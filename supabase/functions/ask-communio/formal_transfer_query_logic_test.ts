import {
  formalTransferAnswer,
  memberFormalTransferAnswer,
} from "./formal_transfer_query_logic.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (!Object.is(actual, expected)) {
    throw new Error(
      `expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("formal transfer answers preserve success and precise zero semantics", () => {
  assertEquals(
    formalTransferAnswer("St. Antony Community", 2015, [{
      display_name: "Bro. Francis Mundaplackal",
      to_community_name: "Morning Star Community",
      effective_date: "2015-07-01",
    }]),
    "1 formal transfer is recorded from St. Antony Community in 2015:\n• Bro. Francis Mundaplackal → Morning Star Community — 2015-07-01",
  );
  assertEquals(
    formalTransferAnswer("St. Antony Community", 2014, []),
    "I found no recorded formal transfers from St. Antony Community in 2014.",
  );
});

Deno.test("member transfer history and reasons retain transfer-specific semantics", () => {
  assertEquals(
    memberFormalTransferAnswer("Antony Antony", []),
    "I found no recorded formal transfer for Antony Antony.",
  );
  assertEquals(
    memberFormalTransferAnswer("Joseph Varghese", [{
      from_community_name: "St. Antony Community",
      to_community_name: "Morning Star Community",
      effective_date: "2005-01-01",
      reason: "New community assignment",
    }], true),
    "Joseph Varghese has a recorded formal transfer: St. Antony Community to Morning Star Community, effective 2005-01-01. Recorded reason: New community assignment.",
  );
});

Deno.test("formal transfers can never be inferred from adjacent assignments", async () => {
  const index = await Deno.readTextFile(new URL("./index.ts", import.meta.url));
  const handlerStart = index.indexOf("async function formalTransferSearch");
  const handlerEnd = index.indexOf("\nasync function", handlerStart + 20);
  const handler = index.slice(handlerStart, handlerEnd);
  if (!handler.includes('.from("v_member_transfers")')) {
    throw new Error("formal transfer handler must use v_member_transfers");
  }
  if (handler.includes("member_community_assignments")) {
    throw new Error("formal transfer handler must not inspect assignments");
  }
  if (!handler.includes('"CONFIRMED"')) {
    throw new Error("formal transfer handler must require confirmed records");
  }
  if (!handler.includes('"Formal transfer"')) {
    throw new Error("formal transfer evidence label must be human-facing");
  }
});
