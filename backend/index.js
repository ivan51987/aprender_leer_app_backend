const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const { pool, initDB } = require("./database");

process.on("uncaughtException", (err) => {
  console.error("CRITICAL: Uncaught Exception:", err);
  console.error(err.stack);
});

process.on("unhandledRejection", (reason, promise) => {
  console.error(
    "CRITICAL: Unhandled Rejection at:",
    promise,
    "reason:",
    reason,
  );
});

// Initialize the database tables on startup
initDB();

const CONFIG_PATH = path.join(__dirname, "data", "reading-config.json");

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) {
    throw new Error("No se encontró el archivo de configuración.");
  }
  const content = fs.readFileSync(CONFIG_PATH, "utf8");
  return JSON.parse(content);
}

function sanitizeFileName(input = "") {
  return (
    input
      .trim()
      .replace(/ñ/g, "enie")
      .replace(/Ñ/g, "enie")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-zA-Z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .toLowerCase() || "audio"
  );
}

function resolveItemFilePath(categoryId, entry) {
  const fileNameHint =
    entry.fileName ??
    entry.label ??
    entry.text ??
    entry.value ??
    entry.spoken ??
    "";
  const safe = sanitizeFileName(fileNameHint);
  return path.join(categoryId, `${safe}.mp3`);
}

function mapCategoryItems(categoryId, items, mp3BaseUrl, mp3Root) {
  return (items || []).map((entry) => {
    const normalized = typeof entry === "string" ? { text: entry } : entry;
    const text = normalized.text ?? normalized.value ?? "";
    const speech = normalized.speech ?? normalized.audioText ?? text;
    const relativePath = resolveItemFilePath(categoryId, normalized);
    const absolutePath = path.join(mp3Root, relativePath);
    return {
      id: `${categoryId}-${sanitizeFileName(text)}`,
      text,
      speech,
      file: {
        exists: fs.existsSync(absolutePath),
        url: `${mp3BaseUrl}/${relativePath.replace(/\\/g, "/")}`,
      },
    };
  });
}

function buildCategorySummary(category, mp3BaseUrl, mp3Root) {
  const items = mapCategoryItems(
    category.id ?? "general",
    category.items,
    mp3BaseUrl,
    mp3Root,
  );
  return {
    id: category.id ?? "general",
    label: category.label ?? category.id,
    description: category.description ?? category.fallbackTemplate ?? "",
    itemCount: items.length,
    items,
  };
}

const app = express();
app.use(cors());
app.disable("x-powered-by");

// Add request logging
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Middleware to parse JSON bodies
app.use(express.json());

// Helpers for game endpoints
function getBaseUrl(req) {
  return `${req.protocol}://${req.get("host")}`;
}

function mapItemsForGame(categoryId, items, baseUrl, mp3Root) {
  return (items || []).map((entry) => {
    const normalized = typeof entry === "string" ? { text: entry } : entry;
    const text = normalized.text ?? normalized.value ?? "";
    const relativePath = resolveItemFilePath(categoryId, normalized);
    return {
      id: `${categoryId}-${sanitizeFileName(text)}`,
      text,
      audioUrl: `${baseUrl}/mp3/${relativePath.replace(/\\/g, "/")}`,
    };
  });
}

function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.get("/api/config", (req, res) => {
  try {
    const config = loadConfig();
    res.json(config);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get("/api/categories", (req, res) => {
  try {
    const config = loadConfig();
    const mp3Root = path.resolve(process.cwd(), config.outputRoot ?? "mp3");
    const mp3BaseUrl = "/mp3";
    const categories = (config.categories || []).map((category) =>
      buildCategorySummary(category, mp3BaseUrl, mp3Root),
    );
    res.json({
      metadata: config.metadata ?? null,
      totalCategories: categories.length,
      categories,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get("/api/categories/:id", (req, res) => {
  try {
    const config = loadConfig();
    const mp3Root = path.resolve(process.cwd(), config.outputRoot ?? "mp3");
    const mp3BaseUrl = "/mp3";
    const category = (config.categories || []).find(
      (cat) => cat.id === req.params.id,
    );
    if (!category) {
      return res.status(404).json({ error: "Categoría no encontrada." });
    }
    res.json(buildCategorySummary(category, mp3BaseUrl, mp3Root));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/game/lesson/:categoryId
app.get("/api/game/lesson/:categoryId", (req, res) => {
  try {
    const config = loadConfig();
    const mp3Root = path.resolve(process.cwd(), config.outputRoot ?? "mp3");
    const category = (config.categories || []).find(
      (cat) => cat.id === req.params.categoryId,
    );
    if (!category) {
      return res.status(404).json({ error: "Categoría no encontrada." });
    }
    const baseUrl = getBaseUrl(req);
    const items = mapItemsForGame(
      category.id,
      category.items,
      baseUrl,
      mp3Root,
    );
    res.json({ categoryId: category.id, label: category.label, items });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/game/quiz/:categoryId
app.get("/api/game/quiz/:categoryId", (req, res) => {
  try {
    const config = loadConfig();
    const mp3Root = path.resolve(process.cwd(), config.outputRoot ?? "mp3");
    const category = (config.categories || []).find(
      (cat) => cat.id === req.params.categoryId,
    );
    if (!category) {
      return res.status(404).json({ error: "Categoría no encontrada." });
    }
    const baseUrl = getBaseUrl(req);
    const allItems = mapItemsForGame(
      category.id,
      category.items,
      baseUrl,
      mp3Root,
    );
    if (allItems.length < 4) {
      return res.status(422).json({
        error: "La categoría necesita al menos 4 ítems para generar un quiz.",
      });
    }
    const questionCount = Math.min(5, allItems.length);
    const shuffledItems = shuffle(allItems);
    const pickedItems = shuffledItems.slice(0, questionCount);
    const questions = pickedItems.map((correctItem) => {
      const distractors = shuffle(
        allItems.filter((it) => it.id !== correctItem.id),
      ).slice(0, 3);
      const options = shuffle([
        correctItem.text,
        ...distractors.map((d) => d.text),
      ]);
      return {
        prompt: correctItem.text,
        audioUrl: correctItem.audioUrl,
        options,
        correctAnswer: correctItem.text,
      };
    });
    res.json({ categoryId: category.id, label: category.label, questions });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post("/api/scores", async (req, res) => {
  try {
    const { nino_id, categoria, juego_tipo, puntuacion, estrellas } = req.body;
    console.log("Backend: Recibida puntuación:", {
      nino_id,
      categoria,
      juego_tipo,
      puntuacion,
      estrellas,
    });

    if (!nino_id || !categoria || puntuacion === undefined) {
      console.log("Backend: Faltan campos en puntuación");
      return res.status(400).json({
        error: "Faltan campos requeridos (nino_id, categoria, puntuacion)",
      });
    }
    const query = `
      INSERT INTO puntuaciones (nino_id, categoria, juego_tipo, puntuacion, estrellas)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (nino_id, categoria, juego_tipo)
      DO UPDATE SET 
        puntuacion = EXCLUDED.puntuacion,
        estrellas = EXCLUDED.estrellas,
        fecha = CURRENT_TIMESTAMP
      RETURNING id
    `;
    const result = await pool.query(query, [
      nino_id,
      categoria,
      juego_tipo,
      puntuacion,
      estrellas,
    ]);
    res.json({ success: true, score_id: result.rows[0].id });
  } catch (error) {
    console.error("Backend: Error saving score:", error);
    res
      .status(500)
      .json({ error: "Error del servidor al guardar puntuación." });
  }
});

// Get words mastered by a child (score >= 80)
app.get("/api/ninos/:id/mastered-words", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `SELECT DISTINCT categoria, puntuacion 
       FROM puntuaciones 
       WHERE nino_id = $1 AND puntuacion >= 80
       LIMIT 50`,
      [id],
    );
    res.json({ mastered: result.rows });
  } catch (error) {
    console.error("Error fetching mastered words:", error);
    res.status(500).json({ error: "Error fetching mastered words" });
  }
});

app.get("/api/ninos/:id/stats", async (req, res) => {
  try {
    const { id } = req.params;

    // 1. Stars from "Aprender" (juego_tipo = 'lesson')
    const aprenderResult = await pool.query(
      "SELECT SUM(estrellas) as stars FROM puntuaciones WHERE nino_id = $1 AND juego_tipo = 'lesson'",
      [id],
    );
    const starsAprender = parseInt(aprenderResult.rows[0].stars || 0);

    // 2. Stars from "Desafíos" (juego_tipo IN ('completar', 'sopa', ...))
    const desafiosResult = await pool.query(
      "SELECT SUM(estrellas) as stars FROM puntuaciones WHERE nino_id = $1 AND juego_tipo != 'lesson'",
      [id],
    );
    const starsDesafios = parseInt(desafiosResult.rows[0].stars || 0);

    // 3. Stars from "Biblioteca" (each learned item = 1 star)
    const bibliotecaResult = await pool.query(
      "SELECT SUM(stars) as stars FROM aprendidos WHERE nino_id = $1",
      [id],
    );
    const starsBiblioteca = parseInt(bibliotecaResult.rows[0].stars || 0);

    const totalStars = starsAprender + starsDesafios + starsBiblioteca;

    // Calculate level (10 stars per level)
    const level = Math.floor(totalStars / 10) + 1;

    // Calculate gems: 10 stars = 5 gems + bonus from rewards
    const rewardResult = await pool.query(
      "SELECT SUM(cantidad) as total_bonus FROM recompensas WHERE nino_id = $1",
      [id],
    );
    const totalBonus = parseInt(rewardResult.rows[0].total_bonus || 0);
    const gems = Math.floor(totalStars / 10) * 5 + totalBonus;

    // Calculate streak
    const streakResult = await pool.query(
      `
      WITH dates AS (
        SELECT DISTINCT DATE_TRUNC('day', fecha) as day
        FROM puntuaciones
        WHERE nino_id = $1
      ),
      ordered AS (
        SELECT day, day - (row_number() OVER (ORDER BY day) * INTERVAL '1 day') as grp
        FROM dates
      ),
      streaks AS (
        SELECT COUNT(*) as streak_length, MAX(day) as last_day
        FROM ordered
        GROUP BY grp
      )
      SELECT streak_length
      FROM streaks
      WHERE last_day >= CURRENT_DATE - INTERVAL '1 day'
      ORDER BY last_day DESC
      LIMIT 1
    `,
      [id],
    );

    const streak =
      streakResult.rows.length > 0
        ? parseInt(streakResult.rows[0].streak_length)
        : 0;

    // Get mastery
    const masteryResult = await pool.query(
      "SELECT categoria, MAX(estrellas) as max_stars FROM puntuaciones WHERE nino_id = $1 GROUP BY categoria",
      [id],
    );
    const category_progress = {};
    masteryResult.rows.forEach((row) => {
      category_progress[row.categoria] = parseInt(row.max_stars);
    });

    res.json({
      level,
      gems,
      streak,
      totalStars,
      starsAprender,
      starsBiblioteca,
      starsDesafios,
      category_progress,
    });
  } catch (error) {
    console.error("Error fetching stats:", error);
    res.status(500).json({ error: "Error fetching student statistics" });
  }
});

app.post("/api/ninos", async (req, res) => {
  try {
    const { nombre } = req.body;
    if (!nombre || nombre.trim() === "") {
      return res.status(400).json({ error: "El nombre es requerido" });
    }

    const trimmedName = nombre.trim();

    // Check if child already exists (accent and case insensitive)
    const normalizedQuery = `
      SELECT id, nombre FROM ninos 
      WHERE TRANSLATE(LOWER(nombre), 'áéíóúüÁÉÍÓÚÜñÑ', 'aeiouuaeiounn') = 
            TRANSLATE(LOWER($1), 'áéíóúüÁÉÍÓÚÜñÑ', 'aeiouuaeiounn')
    `;
    const checkResult = await pool.query(normalizedQuery, [trimmedName]);

    if (checkResult.rows.length > 0) {
      console.log(
        `Backend: Niño existente encontrado: ${trimmedName} (ID: ${checkResult.rows[0].id})`,
      );
      return res.json({
        success: true,
        child: checkResult.rows[0],
        existing: true,
      });
    }

    const result = await pool.query(
      "INSERT INTO ninos (nombre) VALUES ($1) RETURNING id, nombre",
      [trimmedName],
    );
    console.log(
      `Backend: Nuevo niño registrado: ${trimmedName} (ID: ${result.rows[0].id})`,
    );
    res.json({ success: true, child: result.rows[0], existing: false });
  } catch (error) {
    console.error("Backend: Error registrando/buscando niño:", error);
    res.status(500).json({ error: "Error del servidor al registrar." });
  }
});

app.post("/api/ninos/:id/learn", async (req, res) => {
  const { id } = req.params;
  const { item, category } = req.body;

  if (!item || !category) {
    return res.status(400).json({ error: "Item and category are required" });
  }

  try {
    const check = await pool.query(
      "SELECT id FROM aprendidos WHERE nino_id = $1 AND item_texto = $2",
      [id, item],
    );

    if (check.rows.length > 0) {
      return res.json({
        success: true,
        message: "Already learned",
        newlyLearned: false,
      });
    }

    await pool.query(
      "INSERT INTO aprendidos (nino_id, item_texto, categoria) VALUES ($1, $2, $3)",
      [id, item, category],
    );

    res.json({
      success: true,
      message: "Item learned! +5 gems",
      newlyLearned: true,
    });
  } catch (error) {
    console.error("Error saving learned item:", error);
    res.status(500).json({ error: "Error del servidor" });
  }
});

app.get("/api/leaderboard", async (req, res) => {
  try {
    const query = `
      SELECT n.id, n.nombre, 
             COALESCE((SELECT SUM(estrellas) FROM puntuaciones WHERE nino_id = n.id), 0) +
             COALESCE((SELECT SUM(stars) FROM aprendidos WHERE nino_id = n.id), 0) as total_stars
      FROM ninos n
      ORDER BY total_stars DESC
      LIMIT 5
    `;
    const result = await pool.query(query);
    const leaderboard = result.rows.map((row) => ({
      ...row,
      level: Math.floor(parseInt(row.total_stars) / 10) + 1,
    }));
    res.json(leaderboard);
  } catch (error) {
    console.error("Error fetching leaderboard:", error);
    res.status(500).json({ error: "Error fetching leaderboard" });
  }
});

app.get("/api/ninos/:id/rank", async (req, res) => {
  const { id } = req.params;
  try {
    const query = `
      WITH totals AS (
        SELECT n.id as nino_id,
               COALESCE((SELECT SUM(estrellas) FROM puntuaciones WHERE nino_id = n.id), 0) +
               COALESCE((SELECT SUM(stars) FROM aprendidos WHERE nino_id = n.id), 0) as total_stars
        FROM ninos n
      ),
      ranked AS (
        SELECT nino_id, RANK() OVER (ORDER BY total_stars DESC) as rank
        FROM totals
      )
      SELECT rank FROM ranked WHERE nino_id = $1
    `;
    const result = await pool.query(query, [id]);
    const rank = result.rows.length > 0 ? parseInt(result.rows[0].rank) : null;
    res.json({ rank });
  } catch (error) {
    console.error("Error fetching rank:", error);
    res.status(500).json({ error: "Error fetching rank" });
  }
});

app.post("/api/ninos/:id/reward", async (req, res) => {
  const { id } = req.params;
  const { type, amount } = req.body;

  if (!type || !amount) {
    return res.status(400).json({ error: "Type and amount are required" });
  }

  try {
    await pool.query(
      "INSERT INTO recompensas (nino_id, tipo, cantidad) VALUES ($1, $2, $3)",
      [id, type, amount],
    );
    res.json({ success: true, message: `Reward added: ${amount} gems` });
  } catch (error) {
    console.error("Error saving reward:", error);
    res.status(500).json({ error: "Error del servidor" });
  }
});

const config = loadConfig();
const mp3Root = path.resolve(process.cwd(), config.outputRoot ?? "mp3");
app.use("/mp3", express.static(mp3Root));

const PORT = 4001;
const HOST = "0.0.0.0";

app.listen(PORT, HOST, () => {
  console.log(`Backend corriendo en http://${HOST}:${PORT}`);
});
