# Firestore Index Configuration

Based on the runtime errors, the following Firestore indexes need to be created for optimal query performance:

## Required Indexes

### Jobs Collection
The following indexes are required for the job matching and filtering queries:

1. **Composite Index for Job Discovery:**
   - Collection: `jobs`
   - Fields:
     - `status` (Ascending)
     - `location` (Ascending)
     - `hourlyRate` (Descending)

2. **Composite Index for Certificate Matching:**
   - Collection: `jobs`
   - Fields:
     - `status` (Ascending)
     - `requiredCertificates` (Array)
     - `createdAt` (Descending)

3. **Composite Index for Location-based Queries:**
   - Collection: `jobs`
   - Fields:
     - `status` (Ascending)
     - `latitude` (Ascending)
     - `longitude` (Ascending)

### Applications Collection
4. **User Applications Index:**
   - Collection: `job_applications`
   - Fields:
     - `guardId` (Ascending)
     - `status` (Ascending)
     - `appliedAt` (Descending)

5. **Company Applications Index:**
   - Collection: `job_applications`  
   - Fields:
     - `companyId` (Ascending)
     - `jobId` (Ascending)
     - `status` (Ascending)

## How to Create Indexes

### Option 1: Firebase Console
1. Go to Firebase Console > Firestore Database > Indexes
2. Click "Create Index"
3. Add the fields and their sort order as specified above

### Option 2: Firebase CLI
```bash
# Install Firebase CLI if not installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy indexes from firestore.indexes.json
firebase deploy --only firestore:indexes
```

### Option 3: Automatic Creation
The indexes will be automatically suggested when running queries that require them. The error messages in the console will provide direct links to create these indexes.

## Index Creation Links
When the application runs and performs queries that require these indexes, Firebase will provide direct creation links in the console errors. These can be used to quickly create the required indexes.

## Performance Impact
- Without these indexes, queries will be limited to 500 documents max
- Index creation may take several minutes for large collections
- Indexes increase storage costs but significantly improve query performance

## Monitoring
After creating indexes, monitor their usage in Firebase Console > Firestore Database > Usage tab to ensure they're being utilized effectively.