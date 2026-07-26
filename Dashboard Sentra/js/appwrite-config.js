// Konfigurasi shared Appwrite client untuk Dashboard Sentra
// Semua halaman JS import dari sini

import { Client, Account, Databases, Query, ID } from 'https://esm.sh/appwrite@16.1.0';

const client = new Client()
    .setEndpoint('https://sgp.cloud.appwrite.io/v1')
    .setProject('6a5a2ab80012a3e5860a');

const account = new Account(client);
const databases = new Databases(client);

const DATABASE_ID = '6a5a2cca002aaa8dd6f8';

const COLLECTION_ORDERS = 'orders';
const COLLECTION_USERS = 'users';
const COLLECTION_COURIERS = 'couriers';

export {
    client, account, databases, Query, ID,
    DATABASE_ID,
    COLLECTION_ORDERS,
    COLLECTION_USERS,
    COLLECTION_COURIERS
};
