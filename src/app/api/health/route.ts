import postgres from 'postgres'
import { connection } from 'next/server'

const sql = postgres(process.env.DATABASE_URL!, { prepare: false })

export async function GET() {
  await connection()
  try {
    await sql`select 1`
    return Response.json({ ok: true })
  } catch {
    return Response.json({ ok: false }, { status: 503 })
  }
}