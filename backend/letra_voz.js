const { EdgeTTS } = require('universal-edge-tts');
const { promises: fs } = require('fs');
const path = require('path');

// ============================================
// CONFIGURACIÓN
// ============================================
const VOICES = Object.freeze({
  female: 'es-MX-JorgeNeural',  // Usamos voz masculina para variar
  male: 'es-MX-JorgeNeural',     // Por ahora ambas iguales
  // female: 'es-MX-DaliaNeural', // Descomentar para voz femenina
});

const PROSODY_OPTIONS = {
  rate: '+0%',
  volume: '+0%',
  pitch: '+0Hz',
  timeout: 10000 // 10 segundos de timeout
};

const MIN_TEXT_FOR_AUDIO = 2;
const MAX_ATTEMPTS = 2;

// ============================================
// FUNCIÓN PRINCIPAL DE SÍNTESIS CON REINTENTOS
// ============================================
async function synthesizeWithRetry(text, voice, options, fallbackTemplate, attempt = 0) {
  // Limpiar el texto antes de enviarlo
  const cleanText = text.trim().replace(/\s+/g, ' ').replace(/\.\.+/g, '.').replace(/\.$/, '');
  
  console.log(`🔊 Sintetizando (intento ${attempt + 1}/${MAX_ATTEMPTS}): "${cleanText}"`);
  
  const tts = new EdgeTTS(cleanText, voice, options);
  
  try {
    const resultado = await tts.synthesize();
    
    // Verificar que realmente hay audio
    if (!resultado?.audio) {
      throw new Error('No se recibió audio en la respuesta');
    }
    
    return resultado;
  } catch (error) {
    // Si es el último intento, lanzar el error
    if (attempt + 1 >= MAX_ATTEMPTS) {
      console.error(`❌ Falló después de ${MAX_ATTEMPTS} intentos:`, error.message);
      throw error;
    }

    // Determinar si debemos reintentar
    const shouldRetry = 
      error?.name === 'NoAudioReceived' || 
      error?.message?.includes('No audio') ||
      error?.message?.includes('timeout') ||
      error?.code === 'ECONNRESET';

    if (shouldRetry) {
      // Construir texto de respaldo más largo
      let fallbackText;
      const normalized = cleanText;
      
      if (normalized.length === 0) {
        fallbackText = 'texto de ejemplo para generar audio';
      } else if (normalized.length <= MIN_TEXT_FOR_AUDIO) {
        // Usar template de respaldo
        fallbackText = fallbackTemplate?.replace('{text}', normalized) ?? 
                      `La letra ${normalized} del abecedario español`;
        
        // Asegurar que el texto sea suficientemente largo
        if (fallbackText.length < 10) {
          fallbackText = `Esta es la letra ${normalized} del abecedario en español`;
        }
      } else {
        fallbackText = normalized;
      }
      
      // Limpiar el texto de respaldo
      fallbackText = fallbackText
        .replace(/\s+/g, ' ')
        .replace(/\.\.+/g, '.')
        .replace(/\.,/g, ',')
        .trim();
      
      console.warn(`⚠️  Reintentando con texto extendido: "${fallbackText}"`);
      
      // Esperar un momento antes de reintentar
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      return synthesizeWithRetry(fallbackText, voice, options, fallbackTemplate, attempt + 1);
    }
    
    throw error;
  }
}

// ============================================
// FUNCIÓN PARA CONSTRUIR EL TEXTO A HABLAR
// ============================================
function buildSpeechText(text, fallbackTemplate) {
  if (!text) return '';
  
  const cleanText = text.trim();
  
  // Para textos muy cortos (letras individuales)
  if (cleanText.length <= MIN_TEXT_FOR_AUDIO) {
    if (fallbackTemplate) {
      // Usar el template sin agregar puntuación extra
      return fallbackTemplate.replace('{text}', cleanText).trim();
    }
    // Template por defecto si no hay ninguno
    return `La letra ${cleanText} del abecedario español`;
  }
  
  return cleanText;
}

// ============================================
// SANITIZAR NOMBRES DE ARCHIVO
// ============================================
function sanitizeFileName(input = '') {
  if (!input) return 'audio';
  
  return input
    .trim()
    .replace(/ñ/g, 'enie')
    .replace(/Ñ/g, 'enie')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Quitar acentos
    .replace(/[^a-zA-Z0-9]+/g, '-')  // Reemplazar caracteres no válidos con guiones
    .replace(/^-+|-+$/g, '')          // Quitar guiones al inicio y final
    .toLowerCase() || 'audio';
}

// ============================================
// VERIFICAR SI ARCHIVO EXISTE
// ============================================
async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

// ============================================
// SELECCIONAR VOZ
// ============================================
function pickVoice(key) {
  const normalized = (key ?? 'female').toLowerCase();
  return VOICES[normalized] ?? VOICES.female;
}

// ============================================
// CREAR DIRECTORIO SI NO EXISTE
// ============================================
async function ensureDirectory(dirPath) {
  await fs.mkdir(dirPath, { recursive: true });
}

// ============================================
// FUNCIÓN PRINCIPAL
// ============================================
async function run() {
  console.log('🎵 Iniciando generación de audios...\n');
  
  // Obtener ruta del archivo de configuración
  const configArg = process.argv[2];
  const configPath = configArg
    ? path.resolve(configArg)
    : path.join(__dirname, 'data', 'reading-config.json');

  console.log(`📁 Usando configuración: ${configPath}\n`);

  // Leer y parsear configuración
  const configContent = await fs.readFile(configPath, 'utf-8');
  const config = JSON.parse(configContent);

  // Crear directorio raíz de salida
  const outputRoot = path.resolve(process.cwd(), config.outputRoot ?? 'mp3');
  await ensureDirectory(outputRoot);
  console.log(`📂 Directorio de salida: ${outputRoot}\n`);

  // Procesar cada categoría
  const categories = Array.isArray(config.categories) ? config.categories : [];
  
  for (const category of categories) {
    const voiceName = pickVoice(category.voice ?? config.defaultVoice);
    const categoryId = category.id ?? 'general';
    const categoryLabel = category.label ?? categoryId;
    const categoryDir = path.join(outputRoot, categoryId);
    
    console.log(`\n🔄 Procesando categoría: ${categoryLabel}`);
    await ensureDirectory(categoryDir);

    const items = Array.isArray(category.items) ? category.items : [];
    let generated = 0;
    let skipped = 0;
    let errors = 0;

    for (const item of items) {
      // Normalizar entrada (puede ser string u objeto)
      const entry = typeof item === 'string' ? { text: item } : item || {};
      const text = (entry.text ?? entry.value ?? '').trim();
      
      if (!text) {
        console.warn(`  ⚠️  Entrada vacía ignorada`);
        continue;
      }

      // Determinar nombre del archivo
      const fileNameHint = entry.fileName ?? entry.label ?? text;
      const safeFileName = sanitizeFileName(fileNameHint);
      const targetPath = path.join(categoryDir, `${safeFileName}.mp3`);

      // Verificar si ya existe
      if (await fileExists(targetPath)) {
        console.log(`  ✓ ${text} ya existe, saltando...`);
        skipped++;
        continue;
      }

      console.log(`  ⚙️  Generando: ${text}`);

      try {
        // Obtener template de respaldo
        const fallbackTemplate = 
          entry.fallbackTemplate ??
          entry.fallback ??
          category.fallbackTemplate ??
          config.fallbackTemplate ??
          'Esta es la letra {text} del abecedario en español';

        // Construir texto a sintetizar
        const speechText = 
          entry.speech ?? 
          entry.speak ?? 
          entry.audioText ?? 
          entry.spoken ?? 
          buildSpeechText(text, fallbackTemplate);

        // Generar audio
        const resultado = await synthesizeWithRetry(
          speechText,
          voiceName,
          PROSODY_OPTIONS,
          fallbackTemplate
        );

        // Guardar archivo
        const audioBuffer = Buffer.from(await resultado.audio.arrayBuffer());
        await fs.writeFile(targetPath, audioBuffer);
        
        console.log(`  ✅ Guardado: ${targetPath}`);
        generated++;

        // Pequeña pausa entre generaciones para no saturar el servicio
        await new Promise(resolve => setTimeout(resolve, 500));

      } catch (error) {
        console.error(`  ❌ Error en ${text}:`, error.message);
        errors++;
      }
    }

    // Resumen de la categoría
    console.log(`\n  📊 Resumen ${categoryLabel}:`);
    console.log(`     ✅ Generados: ${generated}`);
    console.log(`     ⏭️  Saltados: ${skipped}`);
    console.log(`     ❌ Errores: ${errors}`);
  }

  // Resumen final
  console.log('\n' + '='.repeat(50));
  console.log('🎉 Proceso completado');
  console.log('='.repeat(50));
}

// ============================================
// MANEJO DE ERRORES GLOBALES
// ============================================
process.on('unhandledRejection', (error) => {
  console.error('❌ Error no manejado:', error);
  process.exit(1);
});

// Ejecutar
run().catch((error) => {
  console.error('❌ Error general:', error);
  process.exit(1);
});