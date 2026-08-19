# kolaa

**An AI operating system for small businesses.** [kolaa.co](https://kolaa.co)

---

## The problem this exists for

A shop owner already has all the data anyone could want about her
business. It is in a WhatsApp thread with a supplier. It is in a notebook
under the counter. It is in her head — she knows the blue Ankara moves
before Christmas and the children's wrappers do not.

None of it is anywhere she can ask a question of.

So the same four things happen every week. A customer asks "do you have
this in red?" at 11pm and gets no answer until morning, by which time they
have bought it somewhere else. Something runs out and nobody notices until
a customer asks for it. An invoice goes unpaid because chasing it means
scrolling back through six weeks of chat. And at the end of the month she
knows roughly how it went, which is not the same as knowing.

The software that solves this exists. It is called an ERP, it costs more
than her rent, it assumes she has an IT person, and it assumes she wants
to type her business into forms for three weeks before it does anything
useful. That is not a price problem. It is a shape problem.

## What kolaa actually is

kolaa is the memory and judgement layer that small business has never had
— the part of an ERP that would have been useful, without the part that
requires a consultant.

Three things, in this order, because the order is the product:

**It remembers.** You give kolaa what you already have — a price list, a
supplier agreement, a photo of your delivery zones scrawled on paper, the
way you actually answer the question about returns. It reads them, keeps
them, and can cite which document an answer came from. Nothing is retyped
into a form.

**It answers.** Customers reach your business on WhatsApp and Telegram
because that is where they already are. kolaa answers them from what your
business knows, in your voice, at 11pm — and hands the conversation to a
human the moment it is out of its depth, rather than guessing.

**It notices.** This is the part that is not a chatbot. kolaa watches what
changes and tells you before you would have found out: what has gone out
of stock, who has been waiting on a reply for two days, which promise to a
named customer is about to be missed. You do not ask. It is on the screen
when you open it in the morning.

The value compounds. A business that has used kolaa for a year has a year
of its own operating knowledge inside it, and that is the thing that is
hard to leave — not the model underneath, which is replaceable by design.

## What it is not

- **Not a chatbot builder.** Answering customers is the doorway, not the
  product. If that were the whole thing, the value would live in whichever
  LLM is cheapest this quarter.
- **Not analytics.** A dashboard of charts hands the interpretation back
  to the owner. kolaa is supposed to have already done that part.
- **Not an AI that invents facts about your business.** Findings are
  computed from your rows by deterministic rules — "this product has 0
  stock" is either true or it is a bug. When a model does write something,
  it is marked, and it never sources a number: prices, stock and totals
  are read from the database at the moment they are displayed, never from
  prose.

