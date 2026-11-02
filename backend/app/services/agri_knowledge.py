"""
AgriVerse AI Expert Agricultural Knowledge Base (ICAR & State Agricultural Universities)
Provides reliable, research-backed packages of practices for fertilizers, pest management,
and irrigation when cloud LLM APIs experience transient timeouts or network spikes.
"""

from typing import Optional, Tuple


def get_expert_agricultural_advisory(query: str, language: str = "en", crop_context: Optional[str] = None) -> str:
    q = query.lower()
    crop = crop_context.lower() if crop_context else ""
    is_te = language.lower() in {"te", "telugu"}

    # Determine Crop
    target_crop = "general"
    if any(k in q for k in ["rice", "paddy", "వరి", "ధాన్యం"]):
        target_crop = "paddy"
    elif any(k in q for k in ["chilli", "mirchi", "మిరప"]):
        target_crop = "chilli"
    elif any(k in q for k in ["cotton", "పత్తి"]):
        target_crop = "cotton"
    elif any(k in q for k in ["groundnut", "peanut", "వేరుశనగ"]):
        target_crop = "groundnut"
    elif any(k in q for k in ["maize", "corn", "మొక్కజొన్న"]):
        target_crop = "maize"
    elif any(k in q for k in ["pulse", "dal", "gram", "పప్పు"]):
        target_crop = "pulses"
    elif "paddy" in crop or "rice" in crop:
        target_crop = "paddy"
    elif "chilli" in crop:
        target_crop = "chilli"
    elif "cotton" in crop:
        target_crop = "cotton"

    # 1. Urea & Nitrogen Management
    if any(k in q for k in ["urea", "nitrogen", "యూరియా", "ఎరువు", "fertilizer", "dosage", "dose", "amount"]):
        if target_crop == "paddy":
            if is_te:
                return (
                    "వరి పంటకు ఎకరాకు సిఫార్సు చేసిన యూరియా మోతాదు మరియు వినియోగ విధానం:\n\n"
                    "• మొత్తం యూరియా: సుమారు 90 నుండి 100 కిలోలు (2 బస్తాలు) ఎకరాకు.\n"
                    "• 1వ విడత (నాటు వేసే సమయంలో): 25-30 కి.గ్రా యూరియాతో పాటు పూర్తి భాస్వరం (SSP/DAP) మరియు సగం పొటాష్ (MOP) వేయండి.\n"
                    "• 2వ విడత (పిలకలు పెట్టే దశ - 20-25 రోజులకు): 40-50 కి.గ్రా యూరియా వేయండి.\n"
                    "• 3వ విడత (చిరుపొట్ట లేదా పూత దశకు ముందు): మిగిలిన 25 కి.గ్రా యూరియా మరియు మిగిలిన పొటాష్ వేయండి.\n\n"
                    "ముఖ్య గమనిక: పొలంలో నీరు బయటకు పోయేటప్పుడు ఎరువులు వేయవద్దు. పొలంలో 2-3 సెం.మీ తేమ ఉండేలా చూసుకుని చల్లండి."
                )
            return (
                "Recommended Urea (Nitrogen) schedule for Rice (Paddy) per acre:\n\n"
                "• Total Requirement: Approximately 90–100 kg (2 bags) of Urea per acre.\n"
                "• 1st Application (Basal / Transplanting): Apply 25–30 kg of Urea along with full Phosphorus (SSP/DAP) and half Potash (MOP).\n"
                "• 2nd Application (Active Tillering, 20–25 days after transplanting): Apply 40–50 kg of Urea.\n"
                "• 3rd Application (Panicle Initiation stage, 40–45 days): Apply the remaining 25 kg of Urea along with remaining Potash.\n\n"
                "Important: Do not apply urea when water is overflowing. Drain excess water, maintain 2–3 cm shallow water level, and broadcast uniformly."
            )

        if target_crop == "chilli":
            if is_te:
                return (
                    "మిరప పంటకు ఎకరాకు సిఫార్సు చేసిన యూరియా ఎరువుల మోతాదు:\n\n"
                    "• మొత్తం యూరియా: సుమారు 120 నుండి 140 కిలోలు ఎకరాకు.\n"
                    "• ఎరువులను ఒకేసారి కాకుండా 4-5 విడతలుగా (నాటిన 20, 40, 60, 80 రోజులలో) సమతుల్యంగా వేయండి.\n"
                    "• డ్రిప్ సౌకర్యం ఉంటే నీటిలో కరిగే ఎరువులు (19:19:19 మరియు 13:0:45) ద్వారా అందించడం ఉత్తమం."
                )
            return (
                "Recommended Urea (Nitrogen) schedule for Chilli per acre:\n\n"
                "• Total Requirement: Approximately 120–140 kg of Urea per acre.\n"
                "• Split Application: Apply in 4–5 equal splits at 20, 40, 60, 80, and 100 days after transplanting.\n"
                "• If drip irrigation is available, fertigation with water-soluble fertilizers (19:19:19 & 13:0:45) yields significantly better results."
            )

        if target_crop == "cotton":
            if is_te:
                return (
                    "పత్తి పంటకు ఎకరాకు సిఫార్సు చేసిన నత్రజని (యూరియా) మోతాదు:\n\n"
                    "• మొత్తం యూరియా: 80 నుండి 90 కిలోలు ఎకరాకు.\n"
                    "• విడతలు: నాటిన 20, 40, 60 మరియు 80 రోజులకు 4 సమాన విడతలలో వేయండి.\n"
                    "• పూత మరియు కాయ దశలలో యూరియాతో పాటు పొటాషియం (MOP) తప్పనిసరిగా అందించండి."
                )
            return (
                "Recommended Urea (Nitrogen) schedule for Cotton per acre:\n\n"
                "• Total Requirement: Approximately 80–90 kg of Urea per acre.\n"
                "• Split Application: Apply in 4 splits at 20, 40, 60, and 80 days after sowing.\n"
                "• Ensure balanced application of Potash (MOP) alongside Urea during flowering and boll formation stages."
            )

    # 2. Pest & Disease Management
    if any(k in q for k in ["pest", "disease", "insect", "worm", "spray", "పురుగు", "తెగులు", "మందు", "blast", "thrips"]):
        if target_crop == "paddy":
            if is_te:
                return (
                    "వరి పంటలో ప్రధాన చీడపీడల నివారణ సూచనలు:\n\n"
                    "• అగ్గి తెగులు (Blast): ట్రైసైక్లాజోల్ 75% WP లీటరు నీటికి 0.6 గ్రాములు పిచికారీ చేయండి.\n"
                    "• కాండం తొలుచు పురుగు (Stem Borer): కార్టాప్ హైడ్రోక్లోరైడ్ 50% SP లీటరు నీటికి 2 గ్రాములు లేదా క్లోరాంట్రానిలిప్రోల్ 18.5% SC ఎకరాకు 60 మి.లీ పిచికారీ చేయండి.\n"
                    "• పొట్ట కుళ్లు తెగులు (Sheath Blight): హెక్సాకోనాజోల్ 5% EC లీటరు నీటికి 2 మి.లీ పిచికారీ చేయండి."
                )
            return (
                "Pest and disease management guidelines for Rice (Paddy):\n\n"
                "• Leaf Blast (Magnaporthe oryzae): Spray Tricyclazole 75% WP @ 0.6 g/liter of water.\n"
                "• Stem Borer: Apply Cartap Hydrochloride 50% SP @ 2 g/liter or Chlorantraniliprole 18.5% SC @ 60 ml/acre.\n"
                "• Sheath Blight: Spray Hexaconazole 5% EC @ 2 ml/liter of water or Validamycin 3% L @ 2.5 ml/liter."
            )

        if target_crop == "chilli":
            if is_te:
                return (
                    "మిరప పంటలో తామర పురుగులు మరియు ఆకు ముడత నివారణ:\n\n"
                    "• తామర పురుగులు (Thrips): వేప నూనె (10,000 ppm) లీటరు నీటికి 2 మి.లీ లేదా ఫిప్రోనిల్ 5% SC 2 మి.లీ పిచికారీ చేయండి.\n"
                    "• నల్లి (Mites): డయాఫెంథియురాన్ 50% WP లీటరు నీటికి 1.25 గ్రాములు పిచికారీ చేయండి.\n"
                    "• పూత రాలకుండా ఉండటానికి ప్లానోఫిక్స్ 4.5% లీటరు నీటికి 0.25 మి.లీ పిచికారీ చేయండి."
                )
            return (
                "Pest and disease management guidelines for Chilli:\n\n"
                "• Thrips (Leaf Curl): Spray Neem Oil (10,000 ppm) @ 2 ml/liter or Fipronil 5% SC @ 2 ml/liter in early morning.\n"
                "• Mites: Spray Diafenthiuron 50% WP @ 1.25 g/liter or Spiromesifen 22.9% SC @ 1 ml/liter.\n"
                "• Flower drop control: Spray Planofix (NAA 4.5% SL) @ 0.25 ml/liter during active flowering."
            )

    # 3. Irrigation Guidelines
    if any(k in q for k in ["water", "irrigation", "నీరు", "తడి", "moisture"]):
        if is_te:
            return (
                "నీటి యాజమాన్య సూచనలు:\n\n"
                "• వేర్ల క్రియాశీల లోతులో తేమను పరిశీలించి నీరు అందించండి.\n"
                "• పూత మరియు గింజ పాలుపోసుకునే దశలలో నీటి ఎద్దడి లేకుండా చూడటం అత్యంత కీలకం.\n"
                "• రాబోయే 24-48 గంటల్లో స్థానిక వర్ష సూచనను గమనించి తడి ఇవ్వండి."
            )
        return (
            "Irrigation and water management advisory:\n\n"
            "• Monitor soil moisture at the active root zone depth (15–30 cm).\n"
            "• Critical stages: Ensure adequate moisture during panicle initiation, flowering, and grain filling.\n"
            "• Account for the local rainfall forecast in your district before scheduling the next irrigation."
        )

    # 4. General Agricultural Query
    if is_te:
        return (
            f"మీ ప్రశ్న: \"{query}\"\n\n"
            "వ్యవసాయ నిపుణుల సలహా:\n"
            "• స్థానిక వాతావరణం మరియు నేల స్వభావాన్ని బట్టి పంట యాజమాన్య పద్ధతులు పాటించండి.\n"
            "• ఎరువులు మరియు పురుగుమందులు వాడే ముందు సంబంధిత రసాయన ప్యాకెట్ పై ఉన్న లేబుల్ సూచనలను గమనించండి.\n"
            "• మరింత స్పష్టమైన వివరాల కొరకు మీ గ్రామ వ్యవసాయ విస్తరణ అధికారి (AEO) లేదా కృషి విజ్ఞాన కేంద్రాన్ని (KVK) సంప్రదించండి."
        )
    return (
        f"Regarding your query: \"{query}\"\n\n"
        "Expert Agricultural Guidance:\n"
        "• Follow University/ICAR Package of Practices tailored to your soil type and current crop stage.\n"
        "• Apply balanced N-P-K nutrition and secondary micronutrients (Zinc, Boron) based on soil test results.\n"
        "• Always consult the registered product label for precise application rates and verify with your local agricultural extension officer."
    )
