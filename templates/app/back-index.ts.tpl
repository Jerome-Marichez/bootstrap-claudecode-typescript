// src/index.ts — {{PROJECT_NAME}} (back)
// Serveur HTTP minimal sans dépendance (node:http) : point de départ à remplacer
// par le vrai back (routes → services → repositories, validation Zod à la frontière).
import { createServer } from 'node:http'

const port = Number(process.env.PORT ?? 3001)

export const server = createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify({ status: 'ok', service: '{{PROJECT_NAME}}' }))
    return
  }
  res.writeHead(404, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify({ error: 'not found' }))
})

// En test (niveau système), le serveur est démarré par le test via listen(0).
if (process.env.NODE_ENV !== 'test') {
  server.listen(port, () => {
    console.log(`{{PROJECT_NAME}} back démarré sur http://localhost:${port}`)
  })
}
