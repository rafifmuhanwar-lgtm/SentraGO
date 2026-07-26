// Order Management — data real dari Appwrite
import {
    databases, Query,
    DATABASE_ID,
    COLLECTION_ORDERS,
    COLLECTION_USERS,
    COLLECTION_COURIERS
} from './appwrite-config.js';
import {
    checkAuth, formatRupiah, formatDate,
    mapStatusLabel, statusBadgeClass
} from './auth.js';

// Cache user & courier lookup
const userCache = {};
const courierCache = {};

async function getUserName(userId) {
    if (!userId) return '-';
    if (userCache[userId]) return userCache[userId];
    try {
        const doc = await databases.getDocument(DATABASE_ID, COLLECTION_USERS, userId);
        const name = doc.name || doc.email || userId;
        userCache[userId] = name;
        return name;
    } catch {
        userCache[userId] = userId;
        return userId;
    }
}

async function getCourierName(courierId) {
    if (!courierId) return '-';
    if (courierCache[courierId]) return courierCache[courierId];
    try {
        const doc = await databases.getDocument(DATABASE_ID, COLLECTION_COURIERS, courierId);
        const name = doc.name || doc.email || courierId;
        courierCache[courierId] = name;
        return name;
    } catch {
        courierCache[courierId] = courierId;
        return courierId;
    }
}

// Render badge status HTML
function renderStatusBadge(status, courierId) {
    const label = mapStatusLabel(status, courierId);
    const cls = statusBadgeClass(status, courierId);
    return `<span class="status-badge ${cls}">${label}</span>`;
}

// Ambil semua data order dan render
async function loadOrders(statusFilter = '', searchQuery = '') {
    try {
        const queries = [Query.orderDesc('$createdAt'), Query.limit(100)];

        if (statusFilter) {
            queries.push(Query.equal('status', statusFilter));
        }

        const response = await databases.listDocuments(DATABASE_ID, COLLECTION_ORDERS, queries);
        const orders = response.documents || [];

        // — Update statistik cards —
        const totalAll = response.total || 0;
        let processCount = 0;
        let deliveryCount = 0;
        let doneCount = 0;

        for (const o of orders) {
            if (o.status === 'completed') doneCount++;
            else if (o.status === 'ongoing') {
                if (o.courierId) deliveryCount++;
                else processCount++;
            }
        }

        document.getElementById('totalOrder').textContent = totalAll;
        document.getElementById('orderProcess').textContent = processCount;
        document.getElementById('orderDelivery').textContent = deliveryCount;
        document.getElementById('orderDone').textContent = doneCount;
        document.getElementById('orderCount').textContent = totalAll + ' Data';

        // — Filter & search client-side —
        let filtered = orders;
        if (statusFilter === 'process') {
            filtered = orders.filter(o => o.status === 'ongoing' && !o.courierId);
        } else if (statusFilter === 'delivery') {
            filtered = orders.filter(o => o.status === 'ongoing' && o.courierId);
        } else if (statusFilter === 'done') {
            filtered = orders.filter(o => o.status === 'completed');
        } else if (statusFilter === 'cancelled') {
            filtered = orders.filter(o => o.status === 'cancelled');
        }

        if (searchQuery) {
            const q = searchQuery.toLowerCase();
            filtered = filtered.filter(o =>
                (o.$id && o.$id.toLowerCase().includes(q)) ||
                (o.title && o.title.toLowerCase().includes(q)) ||
                (o.deliveryAddress && o.deliveryAddress.toLowerCase().includes(q))
            );
        }

        const tbody = document.querySelector('.table table tbody');
        if (!filtered.length) {
            tbody.innerHTML = `<tr><td colspan="7" style="text-align:center;padding:40px 0;color:#888;">
                Belum ada data pesanan
            </td></tr>`;
            return;
        }

        // — Resolve user & courier names —
        const rows = await Promise.all(filtered.map(async (order) => {
            const userName = await getUserName(order.userId);
            const driverName = await getCourierName(order.courierId);
            return { order, userName, driverName };
        }));

        // — Render tabel —
        tbody.innerHTML = rows.map(({ order, userName, driverName }) => `
            <tr>
                <td style="font-family:monospace;font-size:13px;">${order.$id?.slice(0, 12) || '-'}…</td>
                <td>${userName}</td>
                <td>${driverName}</td>
                <td style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">
                    ${order.deliveryAddress || '-'}
                </td>
                <td>${formatRupiah(order.totalAmount || order.totalPrice || 0)}</td>
                <td>${renderStatusBadge(order.status, order.courierId)}</td>
                <td style="font-size:13px;">${formatDate(order.$createdAt || order.createdAt)}</td>
            </tr>
        `).join('');

    } catch (error) {
        console.error('Gagal memuat data pesanan:', error);
        document.querySelector('.table table tbody').innerHTML =
            `<tr><td colspan="7" style="text-align:center;padding:40px 0;color:#e74c3c;">
                Gagal memuat data. Pastikan koneksi ke Appwrite tersedia.
            </td></tr>`;
    }
}

// — Init —
document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();

    // Load awal
    await loadOrders();

    // — Filter dropdown —
    const filterSelect = document.querySelector('.toolbar-right select');
    const searchInput = document.querySelector('.search-user input');

    if (filterSelect) {
        filterSelect.addEventListener('change', () => {
            loadOrders(filterSelect.value, searchInput?.value || '');
        });
    }

    // — Search —
    if (searchInput) {
        let debounceTimer;
        searchInput.addEventListener('input', () => {
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => {
                loadOrders(filterSelect?.value || '', searchInput.value);
            }, 400);
        });
    }
});
