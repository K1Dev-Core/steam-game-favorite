const navLinks = [...document.querySelectorAll('.side-nav a')];
const sections = navLinks.map((link) => document.querySelector(link.getAttribute('href'))).filter(Boolean);
const progress = document.querySelector('#readingProgress');
const toast = document.querySelector('#toast');
let toastTimer;

function showToast(message) {
  toast.textContent = message;
  toast.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('show'), 1600);
}

document.querySelectorAll('.copy-button').forEach((button) => {
  button.addEventListener('click', async () => {
    const code = button.closest('.code-card').querySelector('pre code').innerText;
    try {
      await navigator.clipboard.writeText(code);
      showToast('คัดลอกโค้ดแล้ว');
    } catch (_) {
      showToast('เบราว์เซอร์นี้ไม่อนุญาตให้คัดลอกอัตโนมัติ');
    }
  });
});

const observer = new IntersectionObserver((entries) => {
  const visible = entries.filter((entry) => entry.isIntersecting).sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
  if (!visible) return;
  navLinks.forEach((link) => link.classList.toggle('active', link.hash === `#${visible.target.id}`));
}, { rootMargin: '-18% 0px -68% 0px', threshold: [0, .2, .5] });
sections.forEach((section) => observer.observe(section));

function updateProgress() {
  const max = document.documentElement.scrollHeight - window.innerHeight;
  progress.style.width = `${max > 0 ? (window.scrollY / max) * 100 : 0}%`;
}
window.addEventListener('scroll', updateProgress, { passive: true });
updateProgress();

const sidebar = document.querySelector('#sidebar');
document.querySelector('#menuToggle').addEventListener('click', () => sidebar.classList.toggle('open'));
navLinks.forEach((link) => link.addEventListener('click', () => sidebar.classList.remove('open')));

document.querySelector('#presentMode').addEventListener('click', (event) => {
  document.body.classList.toggle('present-mode');
  const active = document.body.classList.contains('present-mode');
  event.currentTarget.textContent = active ? 'ออกจากโหมดพรีเซนต์' : 'โหมดพรีเซนต์';
  showToast(active ? 'เปิดโหมดพรีเซนต์แล้ว' : 'กลับสู่มุมมองอ่าน');
});

const search = document.querySelector('#searchInput');
function searchSections() {
  const query = search.value.trim().toLocaleLowerCase('th');
  sections.forEach((section) => {
    section.classList.toggle('search-hidden', query.length > 0 && !section.innerText.toLocaleLowerCase('th').includes(query));
  });
  if (query && !sections.some((section) => !section.classList.contains('search-hidden'))) showToast('ไม่พบหัวข้อนี้ในคู่มือ');
}
search.addEventListener('input', searchSections);
document.addEventListener('keydown', (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
    event.preventDefault();
    search.focus();
  }
  if (event.key === 'Escape') {
    search.value = '';
    searchSections();
    search.blur();
    sidebar.classList.remove('open');
  }
});
