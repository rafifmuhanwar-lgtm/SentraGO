// Driver Management — data real dari Appwrite
import {
    databases, Query,
    DATABASE_ID,
    COLLECTION_COURIERS
} from './appwrite-config.js';
import {
    checkAuth, formatDate
} from './auth.js';

async function loadDrivers() {
    try {
        const response = await databases.listDocuments(DATABASE_ID, COLLECTION_COURIERS, [
            Query.orderDesc('$createdAt'),
            Query.limit(100)
        ]);
        const drivers = response.documents || [];
        const totalDriver = response.total || 0;

        // — Statistik berdasarkan status —
        let online = 0, busy = 0, offline = 0;
        for (const d of drivers) {
            const status = (d.status || '').toLowerCase();
            if (status === 'online' || status === 'available') online++;
            else if (status === 'busy' || status === 'on_delivery') busy++;
            else offline++;
        }

        document.getElementById('totalDriver').textContent = totalDriver;
        document.getElementById('driverOnline').textContent = online;
        document.getElementById('driverBusy').textContent = busy;
        document.getElementById('driverOffline').textContent = offline;
        document.getElementById('driverCount').textContent = totalDriver + ' Data';

        const tbody = document.querySelector('.table table tbody');
        if (!drivers.length) {
            tbody.innerHTML = `<tr><td colspan="7" style="text-align:center;padding:40px 0;color:#888;">
                Belum ada data driver
            </td></tr>`;
            return;
        }

        tbody.innerHTML = drivers.map(driver => {
            const statusLabel = driver.status === 'busy' || driver.status === 'on_delivery'
                ? 'Sedang Bertugas'
                : driver.status === 'online' || driver.status === 'available'
                    ? 'Online'
                    : 'Offline';
            const statusClass = driver.status === 'busy' || driver.status === 'on_delivery'
                ? 'status-delivery'
                : driver.status === 'online' || driver.status === 'available'
                    ? 'status-active'
                    : 'status-cancelled';
            const rating = driver.rating || driver.ratingAverage || 0;

            return `
            <tr>
                <td style="font-family:monospace;font-size:13px;">${driver.$id?.slice(0, 12) || '-'}…</td>
                <td>
                    <div class="user-info">
                        <img src="${driver.avatar || 'img/avatar-placeholder.svg'}" alt="Avatar"
                             style="width:36px;height:36px;border-radius:50%;object-fit:cover;"
                             onerror="this.src='img/avatar-placeholder.svg'">
                        <div>
                            <strong>${driver.name || '-'}</strong>
                            <small>${driver.email || ''}</small>
                        </div>
                    </div>
                </td>
                <td>${driver.vehicleType || driver.kendaraan || '-'}</td>
                <td>${driver.vehiclePlate || driver.platNomor || driver.plat || '-'}</td>
                <td>${typeof rating === 'number' ? '⭐ ' + rating.toFixed(1) : '-'}</td>
                <td><span class="${statusClass}">${statusLabel}</span></td>
                <td class="action">
                    <button class="btn-detail">Detail</button>
                    <button class="btn-edit">Edit</button>
                    <button class="btn-delete">Hapus</button>
                </td>
            </tr>
            `;
        }).join('');

    } catch (error) {
        console.error('Gagal memuat data driver:', error);
        document.querySelector('.table table tbody').innerHTML =
            `<tr><td colspan="7" style="text-align:center;padding:40px 0;color:#e74c3c;">
                Gagal memuat data. Pastikan koneksi ke Appwrite tersedia.
            </td></tr>`;
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await loadDrivers();
});
