const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const path = require('path');

// Cari file Service Account Key secara fleksibel
function getServiceAccountPath() {
  const specificFile = path.join(__dirname, 'motomanagekel3-firebase-adminsdk-fbsvc-32131d33a5.json');
  if (fs.existsSync(specificFile)) {
    return specificFile;
  }

  // Cari file service account lain jika ada perubahan nama file adminsdk
  const files = fs.readdirSync(__dirname);
  const found = files.find(f => f.includes('firebase-adminsdk') && f.endsWith('.json'));
  if (found) {
    return path.join(__dirname, found);
  }

  throw new Error('File service account Firebase Admin SDK tidak ditemukan di direktori.');
}

const serviceAccountPath = getServiceAccountPath();
console.log(`Menggunakan Service Account: ${path.basename(serviceAccountPath)}`);
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf-8'));

// Inisialisasi Firebase App & Firestore
initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

// Fungsi rekursif untuk mengunduh seluruh data dalam satu koleksi (termasuk sub-koleksi)
async function fetchCollectionData(collectionRef, indent = '  ') {
  const snapshot = await collectionRef.get();
  const docsList = [];

  for (const doc of snapshot.docs) {
    const docData = {
      _id: doc.id,
      ...doc.data()
    };

    // Cek apakah dokumen ini memiliki sub-koleksi secara dinamis
    const subCollections = await doc.ref.listCollections();
    if (subCollections.length > 0) {
      docData._subcollections = {};
      for (const subCol of subCollections) {
        console.log(`${indent}↳ Ditemukan sub-koleksi: '${subCol.id}' pada dokumen '${doc.id}'`);
        docData._subcollections[subCol.id] = await fetchCollectionData(subCol, indent + '  ');
      }
    }

    docsList.push(docData);
  }

  return docsList;
}

async function exportAllData() {
  console.log('Mulai mendeteksi dan mengunduh SELURUH koleksi dari Firestore...\n');

  // Dapatkan SEMUA root collection secara dinamis langsung dari Firestore (tidak dibatasi hardcode)
  const collections = await db.listCollections();

  if (collections.length === 0) {
    console.log('Tidak ada koleksi yang ditemukan pada database Firestore ini.');
    return;
  }

  console.log(`Total koleksi utama yang terdeteksi (${collections.length}):`);
  collections.forEach(col => console.log(` - ${col.id}`));
  console.log('--------------------------------------------------');

  const result = {};
  let totalDocs = 0;

  for (const col of collections) {
    const colName = col.id;
    console.log(`Mengunduh data koleksi '${colName}'...`);
    const data = await fetchCollectionData(col);
    result[colName] = data;
    totalDocs += data.length;
    console.log(`✓ Koleksi '${colName}' berhasil diunduh (${data.length} dokumen)`);
  }

  const outputFile = path.join(__dirname, 'database_output.json');
  fs.writeFileSync(outputFile, JSON.stringify(result, null, 2), 'utf-8');

  console.log('==================================================');
  console.log(`SUCCESS! Seluruh data (${totalDocs} dokumen total) berhasil disimpan ke:`);
  console.log(`-> ${outputFile}`);
}

exportAllData().catch(err => {
  console.error('\nTerjadi kesalahan saat mengekspor data:', err);
  process.exit(1);
});