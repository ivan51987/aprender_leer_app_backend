module.exports = {
  apps: [{
    name: 'aprender-leer-backend',
    script: 'index.js',
    env: {
      PORT: 4001,
      NODE_ENV: 'development'
    },
    env_production: {
      PORT: 4001,
      NODE_ENV: 'production'
    }
  }]
};
