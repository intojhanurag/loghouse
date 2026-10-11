import { randomBytes } from "node:crypto";

const SERVICES: Record<string, string[]> = {
  api: ["/users", "/orders", "/search", "/health"],
  auth: ["/login", "/logout", "/token/refresh"],
  payments: ["/pay", "/refund", "/webhook/stripe"],
  worker: ["job:email", "job:invoice", "job:cleanup"],
};

const RATE = Number(process.env.RATE ?? 50);

const INCIDENT = process.env.INCIDENT ?? "";

function pickRandom<T>(items: T[]): T {
  return items[Math.floor(Math.random() * items.length)];
}

function pickLevel(isBroken: boolean): string {
  const errorChance = isBroken ? 0.4 : 0.02;
  const warnChance = isBroken ? 0.2 : 0.05;

  const roll = Math.random();
  if (roll < errorChance) return "error";
  if (roll < errorChance + warnChance) return "warn";
  if (roll < 0.95) return "info";
  return "debug";
}

function pickStatus(level: string): number {
  if (level === "error") return pickRandom([500, 502, 503, 504]);
  if (level === "warn") return pickRandom([400, 404, 429]);
  return 200;
}

function pickDuration(isBroken: boolean): number {
  if (isBroken) return Math.round(800 + Math.random() * 4000);
  return Math.round(20 + Math.random() * 200);
}

function pickMessage(level: string, isBroken: boolean): string {
  if (level === "error") return isBroken ? "upstream timeout" : "unexpected error";
  if (level === "warn") return "client error";
  return "request ok";
}

function makeLog(service: string) {
  const isBroken = service === INCIDENT;
  const level = pickLevel(isBroken);

  return {
    ts: new Date().toISOString(),
    service,
    level,
    route: pickRandom(SERVICES[service]),
    status: pickStatus(level),
    duration_ms: pickDuration(isBroken),
    trace_id: randomBytes(16).toString("hex"),
    msg: pickMessage(level, isBroken),
  };
}

const serviceNames = Object.keys(SERVICES);
const logsPerTick = RATE / 10;

setInterval(() => {
  for (let i = 0; i < logsPerTick; i++) {
    const log = makeLog(pickRandom(serviceNames));
    console.log(JSON.stringify(log));
  }
}, 100);

console.error(`generator started: RATE=${RATE}/s INCIDENT=${INCIDENT || "none"}`);
