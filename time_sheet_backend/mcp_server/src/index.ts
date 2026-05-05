import express, { Request, Response } from 'express';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { extractBearer, resolveToken } from './auth.js';
import { registerTools } from './tools.js';

const PORT = Number(process.env.PORT || 8787);

const app = express();
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

// MCP Streamable HTTP — stateless, un serveur par requête.
// Chaque requête authentifie via Bearer PAT, instancie un McpServer scopé
// à l'utilisateur, et enregistre les outils. Pas de sessionId à maintenir.
app.post('/mcp', async (req: Request, res: Response) => {
  const token = extractBearer(req.headers.authorization);
  if (!token) {
    res.status(401).json({
      jsonrpc: '2.0',
      error: { code: -32001, message: 'Token Bearer manquant' },
      id: null,
    });
    return;
  }

  const ctx = await resolveToken(token);
  if (!ctx) {
    res.status(401).json({
      jsonrpc: '2.0',
      error: { code: -32001, message: 'Token invalide, révoqué ou expiré' },
      id: null,
    });
    return;
  }

  const server = new McpServer({
    name: 'time-sheet-mcp',
    version: '0.1.0',
  });

  registerTools(server, ctx);

  const transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: undefined, // mode stateless
  });

  res.on('close', () => {
    transport.close().catch(() => {});
    server.close().catch(() => {});
  });

  try {
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  } catch (err) {
    console.error('[mcp] erreur traitement requête:', err);
    if (!res.headersSent) {
      res.status(500).json({
        jsonrpc: '2.0',
        error: { code: -32603, message: 'Erreur interne' },
        id: null,
      });
    }
  }
});

// GET et DELETE non supportés en mode stateless (pas de session SSE entrante).
app.get('/mcp', (_req, res) => {
  res.status(405).json({
    jsonrpc: '2.0',
    error: { code: -32000, message: 'Méthode non supportée' },
    id: null,
  });
});

app.delete('/mcp', (_req, res) => {
  res.status(405).json({
    jsonrpc: '2.0',
    error: { code: -32000, message: 'Méthode non supportée' },
    id: null,
  });
});

app.listen(PORT, () => {
  console.log(`[mcp] serveur prêt sur :${PORT}`);
  console.log(`[mcp] timezone : ${process.env.TIMEZONE || 'Europe/Zurich'}`);
});
