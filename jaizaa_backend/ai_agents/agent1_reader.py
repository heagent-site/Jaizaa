import os
import fitz
import base64
from agents import Agent, Runner
from .config import run_config, clean_json_output, external_client

VISION_MODEL = "google/gemini-2.5-flash"

VISION_PROMPT = """
You are a specialist medical data extraction system trained on Pakistani laboratory report formats.
Your sole job is to extract EVERY lab test result from this report image with 100% precision.

KNOWN PAKISTANI LAB FORMATS YOU WILL ENCOUNTER:
- Chughtai Lab, Agha Khan University Hospital Lab, Excel Labs, Dr. Essa's Laboratory,
  Islamabad Diagnostic Centre (IDC), National Institute of Health (NIH), Shaukat Khanum,
  South City Hospital Lab, and generic typed/handwritten formats.

FULL EXTRACTION SCOPE — extract ALL of the following when present:

Complete Blood Count (CBC):
  Hemoglobin (Hb/HGB), RBC Count, Hematocrit (HCT/PCV), MCV, MCH, MCHC, RDW,
  WBC/TLC (Total Leukocyte Count), Neutrophils (%), Lymphocytes (%), Monocytes (%),
  Eosinophils (%), Basophils (%), Platelet Count (PLT), MPV, PDW

Liver Function Tests (LFT):
  Total Bilirubin, Direct Bilirubin, Indirect Bilirubin, ALT (SGPT), AST (SGOT),
  ALP (Alkaline Phosphatase), GGT (Gamma GT), Total Protein, Albumin, Globulin,
  A/G Ratio, PT (Prothrombin Time), INR

Renal / Kidney Function Tests (RFT/KFT):
  Serum Creatinine, Blood Urea Nitrogen (BUN), Serum Urea, Uric Acid,
  eGFR (estimated GFR), Serum Sodium (Na+), Serum Potassium (K+),
  Serum Chloride (Cl-), Serum Bicarbonate (HCO3-), Serum Calcium, Serum Phosphorus,
  Serum Magnesium

Diabetes / Glucose:
  Fasting Blood Sugar (FBS), Random Blood Sugar (RBS), 2-Hour Post-Prandial (2HPP),
  HbA1c (Glycated Hemoglobin), Fasting Insulin, C-Peptide, HOMA-IR

Lipid Profile:
  Total Cholesterol, LDL Cholesterol, HDL Cholesterol, Triglycerides (TG),
  VLDL, Non-HDL Cholesterol, LDL/HDL Ratio, Total Cholesterol/HDL Ratio

Thyroid Function Tests (TFT):
  TSH, Free T3 (FT3), Free T4 (FT4), Total T3, Total T4, Anti-TPO Antibodies,
  Anti-Thyroglobulin Antibodies

Cardiac Markers:
  Troponin I, Troponin T (hs-cTnT), CK-MB, CK (Total), LDH, BNP, NT-proBNP,
  D-Dimer, Myoglobin

Inflammatory / Infection Markers:
  CRP (C-Reactive Protein), ESR, Procalcitonin (PCT), Ferritin, Serum Iron,
  TIBC, Transferrin Saturation, LDH

Vitamins / Minerals:
  Vitamin D (25-OH), Vitamin B12, Folate (Folic Acid), Zinc, Copper

Coagulation Panel:
  PT, APTT (aPTT), INR, Fibrinogen, Bleeding Time (BT), Clotting Time (CT)

Urinalysis:
  Urine Glucose, Urine Protein (Albumin), Urine Ketones, Urine Bilirubin,
  Urine Urobilinogen, Urine Blood (Occult), Urine pH, Specific Gravity,
  Urine WBCs, RBCs, Casts, Bacteria, Crystals, Colour, Appearance

Serology / Hepatitis Markers:
  HBsAg, Anti-HCV, HCV RNA Quantitative, HBV DNA, Anti-HBs, Anti-HBc,
  Anti-HAV, HIV Ag/Ab Combo, VDRL, Widal Test, Blood Culture & Sensitivity,
  Urine Culture & Sensitivity

Hormones:
  FSH, LH, Prolactin, Testosterone (Total/Free), Estradiol (E2), Progesterone,
  Cortisol (AM/PM), DHEA-S, AFP (Alpha-Fetoprotein), CEA, CA-125, CA-19-9, PSA

EXTRACTION RULES:
1. Extract EVERY value visible — do not skip any test, even if value seems unusual.
2. Use the EXACT test name as printed in the report (do not paraphrase or abbreviate differently).
3. For numeric values: extract as a number (float or int), NOT as a string.
4. For qualitative results (Positive/Negative/Reactive/Non-Reactive/Trace): capture as-is as a string.
5. For reference ranges: capture exactly as printed, e.g. "3.5-5.0" or "< 200" or "70-100".
6. If any field (value, unit, reference_range) is missing, illegible, or not printed: set to null — NEVER guess or fabricate.
7. If the same test appears twice (e.g. repeated for verification): use the more recent or clearly marked result.
8. Flatten ALL sections (CBC, LFT, RFT, etc.) into a single flat 'values' object.
9. report_date must be YYYY-MM-DD format or null.
10. If patient name is printed, extract it exactly. Otherwise null.

CRITICAL: Return ONLY valid JSON. No explanation. No markdown fences. No preamble.

JSON STRUCTURE:
{
  "patient_name": "string or null",
  "report_date": "YYYY-MM-DD or null",
  "values": {
    "Hemoglobin": {"value": 12.5, "unit": "g/dL", "reference_range": "13.0-17.0"},
    "HbA1c": {"value": 8.4, "unit": "%", "reference_range": "4.0-5.6"},
    "ALT": {"value": 87, "unit": "U/L", "reference_range": "7-56"},
    "HBsAg": {"value": "Reactive", "unit": null, "reference_range": "Non-Reactive"}
  }
}
"""

agent = Agent(
    name="Document Reader",
    instructions="""You are a specialist medical data extraction system trained on Pakistani laboratory report formats.
Your sole job is to extract EVERY lab test result from a text-extracted lab report with 100% precision.

You will receive raw text extracted from a lab report PDF. The text may be:
- Well-structured (tables with columns: Test | Result | Unit | Reference Range)
- Semi-structured (test names and values on the same or adjacent lines)
- Unstructured (paragraph-style with lab values embedded in sentences)

KNOWN PAKISTANI LAB FORMATS:
Chughtai Lab, Agha Khan University Hospital Lab, Excel Labs, Dr. Essa's Laboratory,
Islamabad Diagnostic Centre (IDC), National Institute of Health (NIH), Shaukat Khanum,
South City Hospital Lab, and generic typed formats.

FULL EXTRACTION SCOPE — extract ALL of the following when present:

Complete Blood Count (CBC):
  Hemoglobin (Hb/HGB), RBC Count, Hematocrit (HCT/PCV), MCV, MCH, MCHC, RDW,
  WBC/TLC (Total Leukocyte Count), Neutrophils (%), Lymphocytes (%), Monocytes (%),
  Eosinophils (%), Basophils (%), Platelet Count (PLT), MPV, PDW

Liver Function Tests (LFT):
  Total Bilirubin, Direct Bilirubin, Indirect Bilirubin, ALT (SGPT), AST (SGOT),
  ALP (Alkaline Phosphatase), GGT (Gamma GT), Total Protein, Albumin, Globulin,
  A/G Ratio, PT (Prothrombin Time), INR

Renal / Kidney Function Tests (RFT/KFT):
  Serum Creatinine, BUN (Blood Urea Nitrogen), Serum Urea, Uric Acid, eGFR,
  Serum Sodium (Na+), Serum Potassium (K+), Serum Chloride (Cl-),
  Serum Calcium, Serum Phosphorus, Serum Magnesium

Diabetes / Glucose:
  Fasting Blood Sugar (FBS), Random Blood Sugar (RBS), 2-Hour Post-Prandial (2HPP),
  HbA1c, Fasting Insulin, C-Peptide, HOMA-IR

Lipid Profile:
  Total Cholesterol, LDL Cholesterol, HDL Cholesterol, Triglycerides (TG),
  VLDL, Non-HDL Cholesterol, LDL/HDL Ratio

Thyroid Function Tests (TFT):
  TSH, Free T3 (FT3), Free T4 (FT4), Anti-TPO Antibodies

Cardiac Markers:
  Troponin I, Troponin T, CK-MB, CK Total, LDH, BNP, NT-proBNP, D-Dimer

Inflammatory / Infection Markers:
  CRP, ESR, Procalcitonin (PCT), Ferritin, Serum Iron, TIBC, Transferrin Saturation

Vitamins / Minerals:
  Vitamin D (25-OH), Vitamin B12, Folate, Zinc, Copper

Urinalysis:
  Urine Glucose, Urine Protein, Urine pH, Specific Gravity, Urine RBCs, WBCs,
  Urine Colour, Appearance, Casts, Bacteria

Serology / Hepatitis Markers:
  HBsAg, Anti-HCV, HCV RNA, HBV DNA, Anti-HBs, HIV Ag/Ab, VDRL, Widal Test

Coagulation:
  PT, APTT, INR, Fibrinogen

Hormones:
  FSH, LH, Prolactin, Testosterone, Estradiol, Cortisol, TSH, AFP, PSA, CA-125, CEA

EXTRACTION RULES:
1. Extract EVERY value visible — skip nothing.
2. Use the test name EXACTLY as it appears in the text.
3. Numeric values: extract as a number (float or int).
4. Qualitative results (Positive/Negative/Reactive/Non-Reactive): capture as a string.
5. Reference ranges: extract exactly as printed (e.g. "3.5-5.0", "< 200", "Negative").
6. Missing, illegible, or not-printed fields: set to null — NEVER guess or fabricate.
7. Flatten ALL panels into a single flat 'values' object.
8. report_date: YYYY-MM-DD or null. patient_name: exact name string or null.
9. If a value appears with "H" (High) or "L" (Low) flag in the text, still extract the numeric value.

CRITICAL: Return ONLY valid JSON. No explanation. No markdown fences. No preamble.

JSON STRUCTURE:
{
  "patient_name": "string or null",
  "report_date": "YYYY-MM-DD or null",
  "values": {
    "Hemoglobin": {"value": 10.2, "unit": "g/dL", "reference_range": "13.0-17.0"},
    "HbA1c": {"value": 8.4, "unit": "%", "reference_range": "4.0-5.6"},
    "ALT": {"value": 87, "unit": "U/L", "reference_range": "7-56"},
    "HBsAg": {"value": "Reactive", "unit": null, "reference_range": "Non-Reactive"}
  }
}
"""
)


async def _run_vision(file_path: str) -> dict:
    """
    Encode a file as base64 image and call the vision model directly via
    external_client (bypassing Runner.run which cannot handle image content).
    For PDFs, render page 1 to PNG first using PyMuPDF.
    """
    b64_data = ""
    mime_type = "image/png"

    # For PDFs: render page 1 to PNG
    if file_path.lower().endswith(".pdf"):
        try:
            doc = fitz.open(file_path)
            page = doc.load_page(0)
            pix = page.get_pixmap(dpi=150)
            img_bytes = pix.tobytes("png")
            doc.close()
            b64_data = base64.b64encode(img_bytes).decode()
            print(f"[OK] Rendered PDF page 1 to PNG ({len(img_bytes)} bytes) for vision")
        except Exception as render_err:
            print(f"[WARN] PDF-to-PNG render failed: {render_err}. Reading raw bytes.")

    # For images (or if PDF render failed): read raw file bytes
    if not b64_data:
        with open(file_path, "rb") as f:
            img_bytes = f.read()
        b64_data = base64.b64encode(img_bytes).decode()

        ext = os.path.splitext(file_path)[1].lower()
        if ext in (".jpg", ".jpeg"):
            mime_type = "image/jpeg"
        elif ext == ".gif":
            mime_type = "image/gif"
        elif ext == ".webp":
            mime_type = "image/webp"
        else:
            mime_type = "image/png"

        print(f"[OK] Encoded {len(img_bytes)} bytes as base64 ({mime_type}) for vision")

    print(f"[INFO] Calling vision model: {VISION_MODEL}")
    response = await external_client.chat.completions.create(
        model=VISION_MODEL,
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": VISION_PROMPT},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:{mime_type};base64,{b64_data}"}
                    }
                ]
            }
        ],
        temperature=0.1,
        max_tokens=1500
    )
    raw_output = response.choices[0].message.content
    data = clean_json_output(raw_output)
    data["extraction_method"] = "vision"
    return data


async def run(file_path: str, file_type: str) -> dict:
    try:
        # ---------------------------------------------------------------
        # PATH A: PDF — try text extraction first
        # ---------------------------------------------------------------
        if file_type == "pdf":
            content = ""
            use_vision = False

            # Pre-flight check
            if not os.path.exists(file_path):
                raise Exception(f"Temp file not found on disk: {file_path}")
            file_size = os.path.getsize(file_path)
            if file_size == 0:
                raise Exception(f"Temp file is empty (0 bytes): {file_path}")
            print(f"[OK] File check passed: {file_path} ({file_size} bytes)")

            try:
                doc = fitz.open(file_path)
                content = "\n".join(page.get_text() for page in doc)
                doc.close()

                if len(content.strip()) < 50:
                    print(f"[WARN] PDF text extraction yielded < 50 chars — likely scanned. Using vision fallback.")
                    use_vision = True
                else:
                    print(f"[OK] Extracted {len(content)} chars from PDF via PyMuPDF")

            except Exception as pdf_err:
                print(f"[WARN] PyMuPDF failed: {pdf_err}. Trying plain-text read.")
                # Second chance: read as plain text (handles text files with .pdf extension)
                try:
                    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                    if len(content.strip()) >= 50:
                        print(f"[OK] Read {len(content)} chars as plain text from file")
                    else:
                        print(f"[WARN] Plain-text read also yielded < 50 chars. Using vision fallback.")
                        use_vision = True
                except Exception as txt_err:
                    print(f"[WARN] Plain-text read also failed: {txt_err}. Using vision fallback.")
                    use_vision = True

            if use_vision:
                # PDF is scanned or unreadable — render to image and OCR
                data = await _run_vision(file_path)
            else:
                # Text-based PDF — use Runner.run() with extracted text
                input_text = f"File type: pdf\nExtracted text:\n{content}"
                result = await Runner.run(agent, input=input_text, run_config=run_config)
                data = clean_json_output(result.final_output)
                data["extraction_method"] = "pdf_text"

        # ---------------------------------------------------------------
        # PATH B: Image file — go directly to vision
        # ---------------------------------------------------------------
        elif file_type == "image":
            data = await _run_vision(file_path)

        else:
            raise Exception(f"Unsupported file_type: {file_type}")

        # Validate output
        if "patient_name" not in data:
            data["patient_name"] = None
        if "report_date" not in data:
            data["report_date"] = None
        if "values" not in data or not data.get("values"):
            raise Exception("LLM returned empty values dict")

        print(f"[OK] Agent 1 extracted {len(data['values'])} lab values via {data['extraction_method']}")
        return data

    except Exception as e:
        print(f"[ERROR] Agent 1 FULL ERROR: {type(e).__name__}: {e}")
        return {
            "error": str(e),
            "patient_name": None,
            "report_date": None,
            "values": {},
            "extraction_method": file_type
        }
