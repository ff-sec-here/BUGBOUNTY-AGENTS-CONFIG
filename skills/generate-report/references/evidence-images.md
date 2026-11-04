# Evidence images

Optional attachments that support the report. Everything here runs locally. Never send
report content, hostnames, tokens, or victim data to a hosted diagram or whiteboard service.

## When to add an image

Add an image only when it removes a question the text cannot:

- **Diagram**: multi-account or multi-hop chains (attacker, victim, server, third party) where
  the order of requests is hard to follow in prose.
- **Screenshot**: the proof of impact (victim data in a response, an executed payload, a changed
  state in the UI) and any UI path that is hard to describe.

Do not add images for single-request bugs that the curl command and response already show.

## Diagrams (Mermaid, offline)

1. Write the diagram to `report-assets/NN-name.mmd`. Keep it small: 3-5 participants, one
   arrow per request, and a label that names the method and path.
2. Render:

   ```
   scripts/render_diagram.sh report-assets/01-flow.mmd report-assets/01-flow.png
   ```

   Uses `mmdc` if installed, otherwise `npx @mermaid-js/mermaid-cli`. Chromium runs with
   `--no-sandbox` via `scripts/puppeteer-config.json`, which Kali needs.
3. Open the PNG and check it. Fix any label that wraps badly or is cut off.

Render to PNG, not SVG. Mermaid SVGs use `foreignObject`, which many viewers and converters
break on.

Example:

```
sequenceDiagram
  participant A as Attacker
  participant S as app.example.com
  A->>S: POST /api/v2/tokens (attacker creds)
  S-->>A: 200 token
  A->>S: GET /api/v2/users/<VICTIM_UUID>/profile + attacker token
  S-->>A: 200 victim email, phone, address
```

## Screenshots: redact and annotate

Always work on a copy. Never overwrite the original capture.

1. Measure. Overlay a grid, open it, and read off coordinates:

   ```
   scripts/redact.py grid shot.png shot-grid.png --step 100
   ```

   Estimating by eye is off by 15-25 px, so measure instead of guessing. The grid image is
   only a measuring aid and is never attached.
2. Apply:

   ```
   scripts/redact.py apply shot.png report-assets/02-response.png \
     --redact 40,120,300,24 \
     --box 40,200,520,60 \
     --label 40,180,"victim data returned"
   ```

   - `--redact x,y,w,h`: opaque black block. Use for tokens, session cookies, emails or names
     of anyone who is not your own test account, API keys, and unrelated third-party data.
   - `--box x,y,w,h`: red outline around the proof.
   - `--label x,y,TEXT`: short red caption.
3. View the output and confirm every sensitive value is covered and the proof is still readable.

Rules:

- Use solid fills only. Do not blur: low-strength blur can be reversed.
- The script re-saves from raw pixels, which drops EXIF and other metadata. If you redact with
  other tools, strip metadata separately (`exiftool -all= file`).
- Do not redact the proof itself. If the evidence is another user's data, use your own victim
  test account so there is nothing to hide.
- Check the program's policy on PII in evidence before attaching.

## Naming and placement

- Directory: `report-assets/` next to the report.
- Files: `NN-short-name.png`, numbered in the order they are referenced (`01-flow.png`,
  `02-response.png`).
- Keep the `.mmd` source next to the PNG so the diagram can be edited.

## Referencing images in the report

Images do not add sections. Reference them by filename inside the existing three:

- In **Steps to Reproduce**, after the step they prove: `Screenshot: 02-response.png`.
- A diagram goes at the top of Steps, right after Requirements: `Flow diagram: 01-flow.png`.
- The text must stand alone. A triager who cannot open the images must still be able to
  reproduce the bug and see what the expected result is.
