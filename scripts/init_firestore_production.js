#!/usr/bin/env node

/**
 * SecuryFlex Firestore Production Initialization Script
 * 
 * This script initializes the production Firestore database with essential
 * configuration data and reference collections.
 * 
 * Usage: node scripts/init_firestore_production.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('../firebase-admin-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'securyflex-dev'
});

const db = admin.firestore();

// Configuration data for SecuryFlex
const initData = {
  // Global app configuration
  app_config: {
    general: {
      app_name: 'SecuryFlex',
      app_version: '1.0.0',
      minimum_supported_version: '1.0.0',
      support_email: 'support@securyflex.nl',
      terms_url: 'https://securyflex.nl/terms',
      privacy_url: 'https://securyflex.nl/privacy',
      contact_phone: '+31 20 123 4567',
      company_address: 'Amsterdam, Nederland',
      default_language: 'nl',
      maintenance_mode: false,
      feature_flags: {
        chat_enabled: true,
        analytics_enabled: true,
        notifications_enabled: true,
        location_tracking_enabled: true
      }
    }
  },

  // Job types and categories
  job_types: [
    { id: 'event_security', name: 'Evenement Beveiliging', description: 'Beveiliging voor evenementen en festivals' },
    { id: 'retail_security', name: 'Winkel Beveiliging', description: 'Beveiliging voor winkels en winkelcentra' },
    { id: 'office_security', name: 'Kantoor Beveiliging', description: 'Beveiliging voor kantoorgebouwen' },
    { id: 'construction_security', name: 'Bouw Beveiliging', description: 'Beveiliging voor bouwplaatsen' },
    { id: 'residential_security', name: 'Wooncomplex Beveiliging', description: 'Beveiliging voor woongebieden' },
    { id: 'transport_security', name: 'Transport Beveiliging', description: 'Beveiliging voor transport en logistiek' }
  ],

  // Job statuses
  job_statuses: [
    { id: 'open', name: 'Open', description: 'Vacature is open voor sollicitaties', color: '#4CAF50' },
    { id: 'closed', name: 'Gesloten', description: 'Vacature is gesloten', color: '#F44336' },
    { id: 'filled', name: 'Vervuld', description: 'Vacature is vervuld', color: '#2196F3' },
    { id: 'paused', name: 'Gepauzeerd', description: 'Vacature is tijdelijk gepauzeerd', color: '#FF9800' }
  ],

  // Application statuses
  application_statuses: [
    { id: 'pending', name: 'In behandeling', description: 'Sollicitatie wordt beoordeeld', color: '#FF9800' },
    { id: 'accepted', name: 'Geaccepteerd', description: 'Sollicitatie is geaccepteerd', color: '#4CAF50' },
    { id: 'rejected', name: 'Afgewezen', description: 'Sollicitatie is afgewezen', color: '#F44336' },
    { id: 'withdrawn', name: 'Ingetrokken', description: 'Sollicitatie is ingetrokken door beveiliger', color: '#9E9E9E' }
  ],

  // Required skills/certifications
  required_skills: [
    { id: 'beveiligingsdiploma_2', name: 'Beveiligingsdiploma 2', description: 'Basis beveiligingsdiploma' },
    { id: 'portofoon_certificaat', name: 'Portofoon Certificaat', description: 'Certificaat voor portofoon gebruik' },
    { id: 'ehbo_certificaat', name: 'EHBO Certificaat', description: 'Eerste Hulp Bij Ongelukken certificaat' },
    { id: 'crowd_control', name: 'Crowd Control', description: 'Ervaring met menigte beheersing' },
    { id: 'surveillance', name: 'Surveillance', description: 'Ervaring met surveillance werkzaamheden' },
    { id: 'access_control', name: 'Toegangscontrole', description: 'Ervaring met toegangscontrole' }
  ],

  // Dutch regions for location filtering
  regions: [
    { id: 'noord_holland', name: 'Noord-Holland', cities: ['Amsterdam', 'Haarlem', 'Alkmaar', 'Hilversum'] },
    { id: 'zuid_holland', name: 'Zuid-Holland', cities: ['Den Haag', 'Rotterdam', 'Leiden', 'Dordrecht'] },
    { id: 'utrecht', name: 'Utrecht', cities: ['Utrecht', 'Amersfoort', 'Nieuwegein', 'Veenendaal'] },
    { id: 'gelderland', name: 'Gelderland', cities: ['Arnhem', 'Nijmegen', 'Apeldoorn', 'Ede'] },
    { id: 'noord_brabant', name: 'Noord-Brabant', cities: ['Eindhoven', 'Tilburg', 'Breda', 'Den Bosch'] },
    { id: 'limburg', name: 'Limburg', cities: ['Maastricht', 'Venlo', 'Heerlen', 'Sittard'] }
  ]
};

/**
 * Initialize a collection with documents
 */
async function initializeCollection(collectionName, documents) {
  console.log(`Initializing ${collectionName} collection...`);
  
  const batch = db.batch();
  
  for (const doc of documents) {
    const docRef = db.collection(collectionName).doc(doc.id);
    batch.set(docRef, {
      ...doc,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  
  await batch.commit();
  console.log(`✅ ${collectionName}: ${documents.length} documents created`);
}

/**
 * Initialize app configuration
 */
async function initializeAppConfig() {
  console.log('Initializing app configuration...');
  
  for (const [docId, data] of Object.entries(initData.app_config)) {
    await db.collection('app_config').doc(docId).set({
      ...data,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  
  console.log('✅ App configuration initialized');
}

/**
 * Main initialization function
 */
async function initializeDatabase() {
  try {
    console.log('🚀 Starting SecuryFlex Firestore initialization...\n');
    
    // Initialize app configuration
    await initializeAppConfig();
    
    // Initialize reference collections
    await initializeCollection('job_types', initData.job_types);
    await initializeCollection('job_statuses', initData.job_statuses);
    await initializeCollection('application_statuses', initData.application_statuses);
    await initializeCollection('required_skills', initData.required_skills);
    await initializeCollection('regions', initData.regions);
    
    console.log('\n✅ SecuryFlex Firestore initialization completed successfully!');
    console.log('\n📊 Summary:');
    console.log(`- App configuration: 1 document`);
    console.log(`- Job types: ${initData.job_types.length} documents`);
    console.log(`- Job statuses: ${initData.job_statuses.length} documents`);
    console.log(`- Application statuses: ${initData.application_statuses.length} documents`);
    console.log(`- Required skills: ${initData.required_skills.length} documents`);
    console.log(`- Regions: ${initData.regions.length} documents`);
    
  } catch (error) {
    console.error('❌ Error initializing database:', error);
    process.exit(1);
  }
}

// Run the initialization
if (require.main === module) {
  initializeDatabase()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('❌ Initialization failed:', error);
      process.exit(1);
    });
}

module.exports = { initializeDatabase, initData };
