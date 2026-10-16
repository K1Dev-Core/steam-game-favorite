const projectId = process.env.FIREBASE_PROJECT_ID || 'test1-f60aa';
const documentRoot = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
const gameFields = [
  'userId', 'appId', 'title', 'description', 'date', 'genre',
  'imageUrl', 'rating', 'isFavorite',
];

function replyError(res, status, message) {
  return res.status(status).json({error: message});
}

function ownerFromToken(req) {
  const authorization = req.headers.authorization || '';
  const match = authorization.match(/^Bearer\s+([\w.-]+)$/);
  if (!match) return null;
  try {
    const parts = match[1].split('.');
    if (parts.length !== 3) return null;
    const claims = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
    if (claims.aud !== projectId || claims.iss !== `https://securetoken.google.com/${projectId}`) return null;
    if (typeof claims.sub !== 'string' || !claims.sub || claims.exp * 1000 <= Date.now()) return null;
    return {uid: claims.sub, token: match[1]};
  } catch (_) {
    return null;
  }
}

function firestoreValue(value) {
  if (typeof value === 'string') return {stringValue: value};
  if (typeof value === 'boolean') return {booleanValue: value};
  if (Number.isInteger(value)) return {integerValue: String(value)};
  if (typeof value === 'number') return {doubleValue: value};
  return {nullValue: null};
}

function firestoreFields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, firestoreValue(value)]));
}

function fromFirestoreValue(value) {
  if ('stringValue' in value) return value.stringValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('timestampValue' in value) return value.timestampValue;
  return null;
}

function fromDocument(document) {
  const data = Object.fromEntries(
    Object.entries(document.fields || {}).map(([key, value]) => [key, fromFirestoreValue(value)]),
  );
  data.id = document.name.split('/').pop();
  return data;
}

function validate(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return 'ข้อมูลเกมไม่ถูกต้อง';
  const title = typeof body.title === 'string' ? body.title.trim() : '';
  const description = typeof body.description === 'string' ? body.description.trim() : '';
  const genre = typeof body.genre === 'string' ? body.genre.trim() : '';
  const imageUrl = typeof body.imageUrl === 'string' ? body.imageUrl : '';
  if (!title || title.length > 120) return 'ชื่อเกมต้องมี 1–120 ตัวอักษร';
  if (!description || description.length > 3000) return 'รายละเอียดต้องมี 1–3000 ตัวอักษร';
  if (!genre || genre.length > 40) return 'กรุณาเลือกหมวดหมู่เกม';
  if (imageUrl.length > 400000) return 'รูปมีขนาดใหญ่เกินไป กรุณาเลือกรูปที่เล็กลง';
  if (imageUrl && !imageUrl.startsWith('https://') && !/^data:image\/(jpeg|png|webp);base64,/.test(imageUrl)) {
    return 'รูปภาพต้องเป็น HTTPS หรือไฟล์รูปที่เลือกจากอุปกรณ์';
  }
  if (typeof body.rating !== 'number' || body.rating < 0 || body.rating > 5) return 'คะแนนต้องอยู่ระหว่าง 0 ถึง 5';
  if (typeof body.isFavorite !== 'boolean') return 'สถานะเกมโปรดไม่ถูกต้อง';
  return null;
}

async function firestoreRequest(path, owner, options = {}) {
  const response = await fetch(`${documentRoot}${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${owner.token}`,
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  let data = {};
  try { data = text ? JSON.parse(text) : {}; } catch (_) {}
  if (!response.ok) {
    const status = response.status === 401 || response.status === 403 ? 403 : response.status;
    const message = status === 403 ? 'ไม่มีสิทธิ์เข้าถึงข้อมูลเกมนี้' : 'บันทึกข้อมูลกับ Firestore ไม่สำเร็จ';
    const error = new Error(message);
    error.status = status;
    throw error;
  }
  return data;
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Accept, Content-Type, Authorization');
  res.setHeader('Cache-Control', 'no-store');
  if (req.method === 'OPTIONS') return res.status(204).end();

  const owner = ownerFromToken(req);
  if (!owner) return replyError(res, 401, 'กรุณาเข้าสู่ระบบใหม่');

  try {
    if (req.method === 'GET') {
      const query = {
        structuredQuery: {
          from: [{collectionId: 'games'}],
          where: {
            fieldFilter: {
              field: {fieldPath: 'userId'},
              op: 'EQUAL',
              value: {stringValue: owner.uid},
            },
          },
        },
      };
      const documents = await firestoreRequest(':runQuery', owner, {
        method: 'POST', body: JSON.stringify(query),
      });
      return res.status(200).json({games: documents.filter((row) => row.document).map((row) => fromDocument(row.document))});
    }

    if (req.method === 'POST' || req.method === 'PUT') {
      const body = req.body;
      const problem = validate(body);
      if (problem) return replyError(res, 400, problem);
      const id = typeof body.id === 'string' ? body.id : '';
      if (!/^[A-Za-z0-9_-]{1,128}$/.test(id)) return replyError(res, 400, 'รหัสเกมไม่ถูกต้อง');
      const now = new Date().toISOString();
      const record = {
        userId: owner.uid,
        appId: String(body.appId || '').slice(0, 30),
        title: body.title.trim(),
        description: body.description.trim(),
        date: String(body.date || now.slice(0, 10)).slice(0, 30),
        genre: body.genre.trim(),
        imageUrl: body.imageUrl,
        rating: body.rating,
        isFavorite: body.isFavorite,
        updatedAt: now,
      };

      let document;
      if (req.method === 'POST') {
        record.createdAt = now;
        document = await firestoreRequest(`/games?documentId=${encodeURIComponent(id)}`, owner, {
          method: 'POST', body: JSON.stringify({fields: firestoreFields(record)}),
        });
      } else {
        const query = new URLSearchParams();
        for (const field of gameFields) query.append('updateMask.fieldPaths', field);
        query.append('updateMask.fieldPaths', 'updatedAt');
        document = await firestoreRequest(`/games/${encodeURIComponent(id)}?${query}`, owner, {
          method: 'PATCH', body: JSON.stringify({fields: firestoreFields(record)}),
        });
      }
      return res.status(req.method === 'POST' ? 201 : 200).json({game: fromDocument(document)});
    }

    if (req.method === 'DELETE') {
      const id = typeof req.query?.id === 'string' ? req.query.id : '';
      if (!/^[A-Za-z0-9_-]{1,128}$/.test(id)) return replyError(res, 400, 'รหัสเกมไม่ถูกต้อง');
      await firestoreRequest(`/games/${encodeURIComponent(id)}`, owner, {method: 'DELETE'});
      return res.status(200).json({deleted: true, id});
    }

    res.setHeader('Allow', 'GET, POST, PUT, DELETE, OPTIONS');
    return replyError(res, 405, 'Method not allowed');
  } catch (error) {
    return replyError(res, error.status || 502, error.message || 'เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ');
  }
};
