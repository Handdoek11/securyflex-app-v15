/// SecuryFlex Terms and Conditions
/// Version 1.0 - January 2025
/// 
/// This file contains the complete terms and conditions for the SecuryFlex platform
/// in compliance with Dutch and European regulations as of 2025.

class TermsAndConditions {
  static const String version = '1.0';
  static const String lastUpdated = 'Januari 2025';
  static const String nextReview = 'Juli 2025';
  
  // Company details
  static const String companyName = 'Securyflex B.V.';
  static const String kvkNumber = '97929344';
  static const String address = 'Amstelkade 7H, 3652MD Woerdense Verlaat';
  static const String website = 'www.securyflex.com';
  static const String email = 'robert@securyflex.com';
  static const String privacyEmail = 'privacy@securyflex.com';
  static const String supportEmail = 'support@securyflex.com';
  static const String phone = '+31 6 54 66 35 49';
  
  // Subscription fees
  static const double zzpMonthlyFee = 4.99;
  static const double smallCompanyFee = 19.99;  // 1-5 employees
  static const double mediumCompanyFee = 29.99; // 6-15 employees
  static const double platformFeePerHour = 2.99;
  
  // Legal limits
  static const int competitionPeriodMonths = 6;
  static const double maxPenaltyAmount = 500.0;
  static const int dataRetentionYears = 7; // Tax requirement
  static const int cookieConsentDays = 365;
  
  /// Get the full terms and conditions text in Dutch
  static String getFullTermsNL() {
    return '''
# SecuryFlex Gebruikersvoorwaarden

**Versie $version - $lastUpdated**
**$companyName | KvK: $kvkNumber | $address**

## 📌 1. ALGEMENE BEPALINGEN

### 1.1 Toepasselijkheid
Deze voorwaarden zijn van toepassing op alle diensten van SecuryFlex B.V. ("Platform"), een bemiddelingsplatform voor beveiligingsdiensten dat voldoet aan:
- Algemene Verordening Gegevensbescherming (AVG/GDPR)
- Digital Services Act (DSA)
- Platform-to-Business Verordening (P2B)
- Wet DBA en handhavingskader 2025

### 1.2 Platformdienst - Geen Werkgeverschap
**BELANGRIJK**: SecuryFlex is uitsluitend een digitaal bemiddelingsplatform. Wij zijn:
- ❌ GEEN werkgever of opdrachtgever
- ❌ GEEN uitzendbureau
- ✅ WEL een neutrale marktplaats voor zelfstandige ondernemers

### 1.3 Aansprakelijkheid
SecuryFlex aanvaardt geen aansprakelijkheid voor:
- Overeenkomsten tussen gebruikers onderling
- Kwaliteit van uitgevoerde diensten
- Schade door onjuiste gebruikersinformatie
Maximale aansprakelijkheid: 1 maand abonnementsgeld

## 💰 2. TARIEVEN & TRANSPARANTIE

### 2.1 Abonnementsstructuur
**ZZP-Beveiligers**: €${zzpMonthlyFee.toStringAsFixed(2)}/maand
- Toegang tot alle opdrachten
- Automatische facturatie-tool
- Beschikbaarheidskalender
- Review systeem

**Beveiligingsbedrijven**:
- 1-5 medewerkers: €${smallCompanyFee.toStringAsFixed(2)}/maand
- 6-15 medewerkers: €${mediumCompanyFee.toStringAsFixed(2)}/maand
- 16+ medewerkers: Op aanvraag

**Opdrachtgevers**: Geen abonnement
- Platformfee: €${platformFeePerHour.toStringAsFixed(2)} per gewerkt uur (transparant vermeld bij boeking)

### 2.2 Betaaltermijnen
- Facturen: 14 dagen na uitvoering
- Automatische incasso abonnementen: Maandelijks vooraf

## 🔒 3. PRIVACY & GEGEVENSBESCHERMING (AVG)

### 3.1 Verwerkingsgrondslag
Wij verwerken persoonsgegevens op basis van:
- **Toestemming**: Voor marketing en niet-essentiële cookies
- **Overeenkomst**: Voor platformdiensten
- **Wettelijke verplichting**: Voor belastingadministratie

### 3.2 Welke Gegevens
**Noodzakelijk**:
- NAW-gegevens, e-mail, telefoon
- KvK-nummer, BTW-nummer
- WPBR-certificaatnummer (beveiligers)

**Met toestemming**:
- Locatiegegevens (alleen tijdens opdracht)
- Profielfoto
- Werkgeschiedenis

### 3.3 Bewaartermijnen
- Fiscale gegevens: $dataRetentionYears jaar (wettelijk verplicht)
- Accountgegevens: 2 jaar na laatste activiteit
- Chatberichten: 6 maanden
- Locatiedata: 24 uur (direct versleuteld opgeslagen)

### 3.4 Uw Rechten
- ✅ Inzage in uw gegevens
- ✅ Correctie/verwijdering
- ✅ Dataportabiliteit
- ✅ Bezwaar tegen verwerking

**Contact**: $privacyEmail
**Klacht**: Autoriteit Persoonsgegevens (www.autoriteitpersoonsgegevens.nl)

### 3.5 Cookies
Wij gebruiken:
- **Functionele cookies**: Geen toestemming vereist
- **Analytische cookies**: Met toestemming
- **Marketingcookies**: Met expliciete toestemming
Cookiebeleid: www.securyflex.nl/cookies

## 👷 4. VOORWAARDEN ZZP-BEVEILIGERS

### 4.1 Zelfstandigheid (Wet DBA Compliant)
Als ZZP'er verklaar je:
- ✅ Zelfstandig ondernemer te zijn met KvK-nummer
- ✅ Vrij te zijn in acceptatie opdrachten
- ✅ Eigen werkwijze te bepalen (binnen veiligheidskaders)
- ✅ Eigen tarieven te hanteren
- ✅ Verantwoordelijk voor eigen belastingen/verzekeringen

### 4.2 Geen Gezagsverhouding
- Platform geeft GEEN instructies over werkuitvoering
- Opdrachtgever mag alleen functionele aanwijzingen geven (locatie, veiligheid)
- Je bent vrij om werk te weigeren of door derden te laten uitvoeren

### 4.3 Concurrentiebeding (Aangepast)
- Duur: $competitionPeriodMonths maanden na laatste opdracht via platform
- Boete bij overtreding: €${maxPenaltyAmount.toStringAsFixed(2)} per incident
- Rechter kan matigen op grond van redelijkheid

## 🏢 5. VOORWAARDEN OPDRACHTGEVERS

### 5.1 Geen Werkgeverschap
U erkent dat:
- ZZP'ers zelfstandig opereren
- Geen sprake is van dienstverband
- U geen gezag uitoefent over werkwijze

### 5.2 Transparantie
- Alle kosten worden vooraf getoond
- Platformfee wordt apart vermeld
- Geen verborgen kosten

## ⚖️ 6. GESCHILLEN & HANDHAVING

### 6.1 Misbruik Platform
Bij fraude, discriminatie of omzeiling platform:
- Eerste overtreding: Waarschuwing
- Tweede overtreding: Tijdelijke schorsing
- Derde overtreding: Permanente uitsluiting
- Boete: Maximaal €${maxPenaltyAmount.toStringAsFixed(2)} (alleen bij aantoonbare schade)

### 6.2 Klachtenprocedure
1. Melding via $supportEmail
2. Reactie binnen 48 uur
3. Oplossing binnen 14 dagen
4. Escalatie naar onafhankelijke mediator mogelijk

### 6.3 Toepasselijk Recht
- Nederlands recht van toepassing
- Geschillen: Rechtbank Midden-Nederland
- ODR-platform EU voor online geschillen beschikbaar

## 📝 7. WIJZIGINGEN & COMMUNICATIE

### 7.1 Wijzigingen Voorwaarden
- Aankondiging minimaal 30 dagen vooraf
- Via e-mail EN in-app notificatie
- Recht op opzegging bij substantiële wijzigingen

### 7.2 Communicatie
- Primair via e-mail
- Belangrijke updates ook via push-notificaties
- Taal: Nederlands (Engels op aanvraag)

## ✅ 8. AKKOORDVERKLARING

Door registratie verklaar je:
1. Deze voorwaarden gelezen en begrepen te hebben
2. Akkoord te gaan met alle bepalingen
3. Naar waarheid gegevens te verstrekken
4. Te voldoen aan wettelijke vereisten voor jouw rol

**Herroepingsrecht**: Consumenten hebben 14 dagen bedenktijd na registratie

## 📞 CONTACT & TOEZICHT

**$companyName**
- Website: $website
- E-mail: $email
- Telefoon: $phone
- KvK: $kvkNumber

**Toezichthouders**:
- Autoriteit Persoonsgegevens (AVG)
- Autoriteit Consument & Markt (Platform regels)
- Belastingdienst (Wet DBA)

**Laatst bijgewerkt**: $lastUpdated
**Volgende review**: $nextReview
''';
  }
  
  /// Get summary points for quick display
  static List<String> getSummaryPoints() {
    return [
      'Platform voor bemiddeling beveiligingsdiensten',
      'ZZP: €${zzpMonthlyFee.toStringAsFixed(2)}/maand',
      'Bedrijven: vanaf €${smallCompanyFee.toStringAsFixed(2)}/maand',
      'Opdrachtgevers: €${platformFeePerHour.toStringAsFixed(2)}/uur platformfee',
      'AVG/GDPR compliant',
      'Wet DBA 2025 compliant',
      '14 dagen herroepingsrecht',
      'Nederlandse wetgeving van toepassing',
    ];
  }
}