// Dashboard — data real dari Appwrite
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

async function loadDashboard() {
    try {
        // — Parallel queries —
        const [usersRes, couriersRes, ordersRes] = await Promise.all([
            databases.listDocuments(DATABASE_ID, COLLECTION_USERS, [Query.limit(1)]),
            databases.listDocuments(DATABASE_ID, COLLECTION_COURIERS, [Query.limit(1)]),
            databases.listDocuments(DATABASE_ID, COLLECTION_ORDERS, [
                Query.limit(100),
                Query.orderDesc('$createdAt')
            ]),
        ]);

        const totalUser = usersRes.total || 0;
        const totalDriver = couriersRes.total || 0;
        const orders = ordersRes.documents || [];
        const totalOrder = ordersRes.total || 0;

        // — Hitung total pendapatan perusahaan (biaya layanan) —
        let totalIncome = 0;
        for (const o of orders) {
            if (o.status === 'completed') {
                totalIncome += (o.biayaLayanan || 0);
            }
        }

        // — Update cards —
        document.getElementById('totalUser').textContent = totalUser;
        document.getElementById('totalDriver').textContent = totalDriver;
        document.getElementById('totalOrder').textContent = totalOrder;
        document.getElementById('totalIncome').textContent = formatRupiah(totalIncome);

        // — Chart mingguan (7 hari) —
        const today = new Date();
        const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
        const last7Days = [];
        const chartData = [];

        for (let i = 6; i >= 0; i--) {
            const d = new Date(today);
            d.setDate(d.getDate() - i);
            last7Days.push(d.toDateString());

            const dayStr = d.toISOString().slice(0, 10);
            // Hitung pesanan yang dibuat di hari itu
            const count = orders.filter(o => {
                const created = o.$createdAt || o.createdAt;
                return created && created.slice(0, 10) === dayStr;
            }).length;
            chartData.push(count);
        }

        const dayLabels = last7Days.map(d => {
            const idx = new Date(d).getDay();
            return dayNames[idx];
        });

        const ctx = document.getElementById('myChart');
        if (ctx && window.Chart) {
            // Hapus chart lama jika ada
            if (window._dashboardChart) {
                window._dashboardChart.destroy();
            }
            window._dashboardChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: dayLabels,
                    datasets: [{
                        label: 'Jumlah Pesanan',
                        data: chartData,
                        fill: true,
                        tension: 0.4,
                        pointRadius: 5,
                        pointHoverRadius: 7,
                        borderWidth: 3,
                        borderColor: '#3498db',
                        backgroundColor: 'rgba(52, 152, 219, 0.1)',
                        pointBackgroundColor: '#3498db'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true, position: 'top' },
                        tooltip: { enabled: true }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: { stepSize: 1 }
                        },
                        x: { grid: { display: false } }
                    }
                }
            });
        }

        // — Recent Orders (5 terbaru) —
        const recentOrders = orders.slice(0, 5);
        const tbody = document.querySelector('.table table tbody');
        if (!recentOrders.length) {
            tbody.innerHTML = `<tr><td colspan="4" style="text-align:center;padding:40px 0;color:#888;">
                Belum ada data pesanan
            </td></tr>`;
            return;
        }

        const rows = await Promise.all(recentOrders.map(async (order) => {
            const userName = await getUserName(order.userId);
            const driverName = await getCourierName(order.courierId);
            return { order, userName, driverName };
        }));

        tbody.innerHTML = rows.map(({ order, userName, driverName }) => `
            <tr>
                <td style="font-family:monospace;font-size:13px;">${order.$id?.slice(0, 12) || '-'}…</td>
                <td>${userName}</td>
                <td>${driverName}</td>
                <td>${renderStatusBadge(order.status, order.courierId)}</td>
            </tr>
        `).join('');

    } catch (error) {
        console.error('Gagal memuat dashboard:', error);
        document.getElementById('totalUser').textContent = '0';
        document.getElementById('totalDriver').textContent = '0';
        document.getElementById('totalOrder').textContent = '0';
        document.getElementById('totalIncome').textContent = 'Rp0';
    }
}

function renderStatusBadge(status, courierId) {
    const label = mapStatusLabel(status, courierId);
    const cls = statusBadgeClass(status, courierId);
    return `<span class="status-badge ${cls}">${label}</span>`;
}

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await loadDashboard();
});
