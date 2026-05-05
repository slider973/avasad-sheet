import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { AuthContext } from './auth.js';
import {
  actionLabel,
  currentState,
  dailyMinutes,
  formatHHmm,
  formatMinutes,
  nextSlot,
  nextSlotKind,
} from './pointage_logic.js';
import { getOrCreateTodayEntry, updateSlot } from './timesheet_repo.js';

const TZ = process.env.TIMEZONE || 'Europe/Zurich';

function text(t: string) {
  return { content: [{ type: 'text' as const, text: t }] };
}

async function performPunch(
  ctx: AuthContext,
  expected: 'in' | 'out' | 'any',
): Promise<{ content: { type: 'text'; text: string }[]; isError?: boolean }> {
  const now = new Date();
  const entry = await getOrCreateTodayEntry(ctx.userId, now, TZ);
  const slot = nextSlot(entry);

  if (slot === null) {
    return {
      isError: true,
      content: [
        {
          type: 'text',
          text: 'Journée déjà complète : les 4 slots sont remplis. Utilise `status` pour voir le détail.',
        },
      ],
    };
  }

  const kind = nextSlotKind(slot);
  if (expected !== 'any' && kind !== expected) {
    const wanted = expected === 'in' ? 'arrivée' : 'sortie';
    return {
      isError: true,
      content: [
        {
          type: 'text',
          text: `Action incohérente : tu demandes un punch ${wanted}, mais le prochain pointage attendu est « ${actionLabel(slot)} ». Utilise l'outil approprié ou \`status\`.`,
        },
      ],
    };
  }

  const hhmm = formatHHmm(now, TZ);
  const updated = await updateSlot(entry.id!, slot, hhmm);
  const minutes = dailyMinutes(updated);

  return text(
    `✓ Pointé : ${actionLabel(slot)} à ${hhmm}\n` +
      `État : ${currentState(updated)}\n` +
      `Total du jour : ${formatMinutes(minutes)}`,
  );
}

export function registerTools(server: McpServer, ctx: AuthContext) {
  server.tool(
    'punch_in',
    'Pointe une arrivée (début de matinée ou reprise après pause). ' +
      'Détermine automatiquement le slot à remplir selon l\'état du jour.',
    {},
    async () => performPunch(ctx, 'in'),
  );

  server.tool(
    'punch_out',
    'Pointe une sortie (pause de midi ou fin de journée). ' +
      'Détermine automatiquement le slot à remplir selon l\'état du jour.',
    {},
    async () => performPunch(ctx, 'out'),
  );

  server.tool(
    'punch',
    'Pointe le prochain événement du jour, quelle que soit sa nature ' +
      '(arrivée, pause, reprise, sortie). À utiliser quand tu veux juste pointer ' +
      'sans te soucier de l\'état actuel.',
    {},
    async () => performPunch(ctx, 'any'),
  );

  server.tool(
    'status',
    'Renvoie l\'état du pointage du jour : les 4 slots, l\'état courant et le total travaillé.',
    {},
    async () => {
      const entry = await getOrCreateTodayEntry(ctx.userId, new Date(), TZ);
      const minutes = dailyMinutes(entry);
      const slot = nextSlot(entry);
      const lines = [
        `Date : ${entry.day_date} (${entry.day_of_week ?? ''})`,
        `État : ${currentState(entry)}`,
        `  Matin     : ${entry.start_morning || '—'} → ${entry.end_morning || '—'}`,
        `  Après-midi: ${entry.start_afternoon || '—'} → ${entry.end_afternoon || '—'}`,
        `Total : ${formatMinutes(minutes)}`,
        slot
          ? `Prochain pointage attendu : ${actionLabel(slot)}`
          : 'Journée complète.',
      ];
      return text(lines.join('\n'));
    },
  );

  server.tool(
    'today_summary',
    'Résumé court et lisible de la journée en cours.',
    {},
    async () => {
      const entry = await getOrCreateTodayEntry(ctx.userId, new Date(), TZ);
      const minutes = dailyMinutes(entry);
      return text(
        `${entry.day_of_week} ${entry.day_date} — ${currentState(entry)} — ${formatMinutes(minutes)} travaillées`,
      );
    },
  );

  // Inutilisé mais réservé : permet à Claude de demander la zone et la date du serveur.
  server.tool(
    'server_now',
    'Retourne l\'heure et le fuseau horaire du serveur MCP.',
    {},
    async () => {
      const now = new Date();
      return text(
        `Maintenant : ${formatHHmm(now, TZ)} (${TZ})\n` +
          `ISO UTC : ${now.toISOString()}`,
      );
    },
  );

  // Z importé pour usage futur (ex: punch_at_time avec un override). Évite warning.
  void z;
}
