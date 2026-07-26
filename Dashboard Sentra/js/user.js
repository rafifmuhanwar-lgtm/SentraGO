// User Management — data real dari Appwrite
import {
    databases, Query,
    DATABASE_ID,
    COLLECTION_USERS
} from './appwrite-config.js';
import {
    checkAuth, formatDate
} from './auth.js';

async function loadUsers() {
    try {
        const response = await databases.listDocuments(DATABASE_ID, COLLECTION_USERS, [
            Query.orderDesc('$createdAt'),
            Query.limit(100)
        ]);
        const users = response.documents || [];
        const totalUser = response.total || 0;

        // — Statistik —
        // Appwrite users tidak punya role "admin" label built-in
        // Untuk sementara admin = 0, hitung active dan new
        let adminCount = 0;
        const activeCount = users.filter(u => u.status !== 'blocked').length;
        const newCount = users.filter(u => {
            const created = u.$createdAt;
            if (!created) return false;
            const days = (Date.now() - new Date(created).getTime()) / (1000 * 60 * 60 * 24);
            return days <= 7;
        }).length;

        document.getElementById('totalUser').textContent = totalUser;
        document.getElementById('totalAdmin').textContent = adminCount;
        document.getElementById('activeUser').textContent = activeCount;
        document.getElementById('newUser').textContent = newCount;
        document.getElementById('userCount').textContent = totalUser + ' Data';

        const tbody = document.querySelector('.table table tbody');
        if (!users.length) {
            tbody.innerHTML = `<tr><td colspan="7" style="text-align:center;padding:40px 0;color:#888;">
                Belum ada data pengguna
            </td></tr>`;
            return;
        }

        tbody.innerHTML = users.map(user => `
            <tr>
                <td style="font-family:monospace;font-size:13px;">${user.$id?.slice(0, 12) || '-'}…</td>
                <td>
                    <div class="user-info">
                        <img src="${user.avatar || 'img/avatar-placeholder.svg'}" alt="Avatar"
                             style="width:36px;height:36px;border-radius:50%;object-fit:cover;"
                             onerror="this.src='img/avatar-placeholder.svg'">
                        <div>
                            <strong>${user.name || '-'}</strong>
                            <small>@${(user.email || '').split('@')[0] || user.$id?.slice(0, 8)}</small>
                        </div>
                    </div>
                </td>
                <td>${user.email || '-'}</td>
                <td><span class="role-user">User</span></td>
                <td><span class="${user.status === 'blocked' ? 'status-cancelled' : 'status-active'}">${user.status === 'blocked' ? 'Nonaktif' : 'Aktif'}</span></td>
                <td style="font-size:13px;">${formatDate(user.$createdAt)}</td>
                <td class="action">
                    <button class="btn-detail">Detail</button>
                    <button class="btn-edit">Edit</button>
                    <button class="btn-delete">Hapus</button>
                </td>
            </tr>
        `).join('');

    } catch (error) {
        console.error('Gagal memuat data user:', error);
        document.querySelector('.table table tbody').innerHTML =
            `<tr><td colspan="7" style="text-align:center;padding:40px 0;color:#e74c3c;">
                Gagal memuat data. Pastikan koneksi ke Appwrite tersedia.
            </td></tr>`;
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await loadUsers();
});
