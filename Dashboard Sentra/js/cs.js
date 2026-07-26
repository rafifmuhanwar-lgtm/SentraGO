import { databases, Query, DATABASE_ID, ID } from './appwrite-config.js';
import { checkAuth, formatDate } from './auth.js';

let currentRoomId = null;
let rooms = [];

async function getUserName(userId) {
    try {
        const doc = await databases.getDocument(DATABASE_ID, 'users', userId);
        return doc.name || doc.email || userId;
    } catch { return userId; }
}

function formatTime(ts) {
    if (!ts) return '';
    try { return new Date(ts).toLocaleString('id-ID', { day:'numeric', month:'short', hour:'2-digit', minute:'2-digit' }); }
    catch { return ts; }
}

async function loadRooms() {
    try {
        const { documents: orders } = await databases.listDocuments(DATABASE_ID, 'orders', [
            Query.limit(100),
            Query.orderDesc('$createdAt'),
        ]);

        const roomMap = {};
        for (const o of orders) {
            if (!o.userId) continue;
            const name = await getUserName(o.userId);
            roomMap[o.$id] = {
                id: o.$id,
                customerName: name,
                userId: o.userId,
                orderTitle: o.title || o.item || 'Pesanan',
                status: o.status,
                type: o.type || 'jastip',
                courierName: o.courierName || '',
            };
        }

        rooms = Object.values(roomMap);
        renderRoomList();
        if (rooms.length > 0 && !currentRoomId) {
            selectRoom(rooms[0].id);
        }
    } catch (e) { console.error(e); }
}

function renderRoomList() {
    const container = document.getElementById('roomItems');
    document.getElementById('roomCount').textContent = rooms.length + ' Chat';
    if (!rooms.length) {
        container.innerHTML = '<div style="padding:20px;text-align:center;color:#999;">Belum ada chat</div>';
        return;
    }
    container.innerHTML = rooms.map(r => `
        <div class="chat-user ${currentRoomId === r.id ? 'active-chat' : ''}"
             onclick="window.selectRoom('${r.id}')">
            <div class="avatar">👤</div>
            <div>
                <b>${r.customerName}</b>
                <p>${r.orderTitle}</p>
            </div>
            <span class="${r.status === 'ongoing' ? 'online' : ''}" style="font-size:10px;">${r.status === 'ongoing' ? '●' : ''}</span>
        </div>
    `).join('');
}

window.selectRoom = async function(roomId) {
    currentRoomId = roomId;
    const room = rooms.find(r => r.id === roomId);
    if (!room) return;

    document.getElementById('chatWith').textContent = room.customerName;
    document.getElementById('roomStatus').textContent = room.status === 'ongoing' ? '● Aktif' : 'Selesai';
    document.getElementById('roomStatus').style.color = room.status === 'ongoing' ? 'green' : '#999';
    document.getElementById('messageInput').disabled = false;
    document.getElementById('sendBtn').disabled = false;
    document.getElementById('autoReplyBox').style.display = 'block';
    renderRoomList();
    await loadMessages(roomId);
};

async function loadMessages(roomId) {
    try {
        const { documents } = await databases.listDocuments(DATABASE_ID, 'chats', [
            Query.equal('orderId', roomId),
            Query.orderAsc('timestamp'),
            Query.limit(200),
        ]);
        const container = document.getElementById('messagesContainer');
        if (!documents.length) {
            container.innerHTML = '<div style="text-align:center;padding:40px;color:#999;">Belum ada pesan.</div>';
            return;
        }
        const room = rooms.find(r => r.id === roomId);
        container.innerHTML = documents.map(msg => {
            const role = msg.senderRole || '';
            const isAdmin = role === 'admin';
            let senderLabel = '';
            if (role === 'admin') senderLabel = 'Admin';
            else if (role === 'courier') senderLabel = room?.courierName || 'Kurir';
            else senderLabel = room?.customerName || 'Customer';
            return `
                <div class="message ${isAdmin ? 'admin' : 'user'}">
                    <small style="display:block;margin-bottom:4px;opacity:0.6;">${senderLabel}</small>
                    ${msg.mediaUrl ? `<img src="${msg.mediaUrl}" style="max-width:200px;border-radius:8px;margin-bottom:4px;">` : ''}
                    ${msg.message || ''}
                    <small style="display:block;margin-top:4px;opacity:0.5;font-size:10px;">${formatTime(msg.timestamp)}</small>
                </div>
            `;
        }).join('');
        container.scrollTop = container.scrollHeight;
    } catch (e) { console.error(e); }
}

window.insertReply = function(text) {
    document.getElementById('messageInput').value = text;
    document.getElementById('messageInput').focus();
};

async function sendMessage() {
    const input = document.getElementById('messageInput');
    const text = input.value.trim();
    if (!text || !currentRoomId) return;
    input.value = '';

    try {
        await databases.createDocument(
            DATABASE_ID, 'chats', ID.unique(), {
                orderId: currentRoomId,
                senderId: 'admin',
                senderName: 'Admin CS',
                senderRole: 'admin',
                message: text,
                timestamp: new Date().toISOString(),
                messageType: 'text',
            }
        );
        await loadMessages(currentRoomId);
    } catch (e) { console.error(e); alert('Gagal kirim: ' + e.message); }
}

document.getElementById('sendBtn').addEventListener('click', sendMessage);
document.getElementById('messageInput').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') sendMessage();
});

// Init
document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await loadRooms();
    setInterval(loadRooms, 5000);
});
