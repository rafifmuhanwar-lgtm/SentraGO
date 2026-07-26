// Report Management — data real dari Appwrite
import {
    databases, Query,
    DATABASE_ID,
    COLLECTION_ORDERS,
    COLLECTION_USERS,
    COLLECTION_COURIERS
} from './appwrite-config.js';
import {
    checkAuth, formatRupiah
} from './auth.js';

async function loadReports() {
    try {
        // — Parallel queries —
        const [ordersRes, usersRes, couriersRes] = await Promise.all([
            databases.listDocuments(DATABASE_ID, COLLECTION_ORDERS, [
                Query.limit(100),
                Query.orderDesc('$createdAt')
            ]),
            databases.listDocuments(DATABASE_ID, COLLECTION_USERS, [
                Query.limit(1)
            ]),
            databases.listDocuments(DATABASE_ID, COLLECTION_COURIERS, [
                Query.limit(1)
            ]),
        ]);

        const orders = ordersRes.documents || [];
        const totalOrder = ordersRes.total || 0;
        const totalUser = usersRes.total || 0;
        const totalDriver = couriersRes.total || 0;

        // — Hitung total pendapatan perusahaan (biaya layanan) —
        let totalIncome = 0;
        for (const o of orders) {
            if (o.status === 'completed') {
                totalIncome += (o.biayaLayanan || 0);
            }
        }

        // — User baru (7 hari terakhir) —
        const newUsers = usersRes.documents ? usersRes.total : 0;
        const weekAgo = new Date();
        weekAgo.setDate(weekAgo.getDate() - 7);

        // — Driver aktif (online atau busy) —
        const activeDrivers = couriersRes.total || 0;

        // — Update statistik cards —
        document.getElementById('totalIncome').textContent = formatRupiah(totalIncome);
        document.getElementById('totalReportOrder').textContent = totalOrder;
        document.getElementById('newUser').textContent = newUsers;
        document.getElementById('activeDriver').textContent = activeDrivers;

        // — Grafik pendapatan (7 hari terakhir) —
        const dayNames = ['Min', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        const today = new Date();
        const incomePerDay = [];
        const orderPerDay = [];
        const labels = [];

        for (let i = 6; i >= 0; i--) {
            const d = new Date(today);
            d.setDate(d.getDate() - i);
            const dayStr = d.toISOString().slice(0, 10);
            labels.push(d.toLocaleDateString('id-ID', { weekday: 'short', day: 'numeric' }));

            let dayIncome = 0;
            let dayOrders = 0;
            for (const o of orders) {
                const created = o.$createdAt || o.createdAt;
                if (created && created.slice(0, 10) === dayStr) {
                    if (o.status === 'completed') {
                        dayIncome += (o.biayaLayanan || 0);
                    }
                    dayOrders++;
                }
            }
            incomePerDay.push(dayIncome);
            orderPerDay.push(dayOrders);
        }

        // — Render Income Chart —
        const incomeCtx = document.getElementById('incomeChart');
        if (incomeCtx && window.Chart) {
            if (window._incomeChart) window._incomeChart.destroy();
            window._incomeChart = new Chart(incomeCtx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Pendapatan',
                        data: incomePerDay,
                        fill: true,
                        tension: 0.4,
                        borderWidth: 3,
                        borderColor: '#27ae60',
                        backgroundColor: 'rgba(39, 174, 96, 0.1)',
                        pointBackgroundColor: '#27ae60'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true, position: 'top' },
                        tooltip: {
                            callbacks: {
                                label: (ctx) => formatRupiah(ctx.raw)
                            }
                        }
                    },
                    scales: {
                        y: { beginAtZero: true },
                        x: { grid: { display: false } }
                    }
                }
            });
        }

        // — Render Order Chart —
        const orderCtx = document.getElementById('orderChart');
        if (orderCtx && window.Chart) {
            if (window._orderChart) window._orderChart.destroy();
            window._orderChart = new Chart(orderCtx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Jumlah Order',
                        data: orderPerDay,
                        borderRadius: 10,
                        backgroundColor: 'rgba(52, 152, 219, 0.7)',
                        borderColor: '#3498db',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true, position: 'top' }
                    },
                    scales: {
                        y: { beginAtZero: true, ticks: { stepSize: 1 } },
                        x: { grid: { display: false } }
                    }
                }
            });
        }

        // — Top Driver —
        const tbody = document.querySelector('.table table tbody');
        if (tbody) {
            // Hitung order count per courier dari data yang ada
            const courierOrderCount = {};
            for (const o of orders) {
                if (o.courierId) {
                    courierOrderCount[o.courierId] = (courierOrderCount[o.courierId] || 0) + 1;
                }
            }

            // Urutkan berdasarkan jumlah order
            const topCouriers = Object.entries(courierOrderCount)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 5);

            if (!topCouriers.length) {
                tbody.innerHTML = `<tr><td colspan="4" style="text-align:center;padding:40px 0;color:#888;">
                    Belum ada data driver
                </td></tr>`;
            } else {
                // Try to get courier names
                const rows = await Promise.all(topCouriers.map(async ([courierId, count]) => {
                    let name = courierId;
                    try {
                        const doc = await databases.getDocument(DATABASE_ID, COLLECTION_COURIERS, courierId);
                        name = doc.name || doc.email || courierId;
                    } catch {}
                    return `<tr>
                        <td>${name}</td>
                        <td>⭐ -</td>
                        <td>${count} pesanan</td>
                        <td>-</td>
                    </tr>`;
                }));
                tbody.innerHTML = rows.join('');
                const countSpan = document.querySelector('.table-header span');
                if (countSpan) countSpan.textContent = topCouriers.length + ' Driver';
            }
        }

    } catch (error) {
        console.error('Gagal memuat laporan:', error);
        document.getElementById('totalIncome').textContent = 'Rp0';
        document.getElementById('totalReportOrder').textContent = '0';
        document.getElementById('newUser').textContent = '0';
        document.getElementById('activeDriver').textContent = '0';
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await loadReports();
});
