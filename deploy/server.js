const { DEFAULT_HOST, createServer } = require('../scripts/tools/serve.js');

const port = parseInt(process.env.PORT, 10) || 8686;

createServer().listen(port, DEFAULT_HOST, () => {
    console.log(`Shuoguang preview listening on http://${DEFAULT_HOST}:${port}`);
});
