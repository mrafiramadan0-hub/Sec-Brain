const modal = document.getElementById('quickModal');
const quickForm = document.getElementById('quickForm');
const taskList = document.getElementById('taskList');
const searchBar = document.getElementById('searchBar');
const globalSearch = document.getElementById('globalSearch');

function openModal() {
    modal.classList.remove('hidden');
    modal.setAttribute('aria-hidden', 'false');
    quickForm.title.focus();
}

function closeModal() {
    modal.classList.add('hidden');
    modal.setAttribute('aria-hidden', 'true');
}

document.getElementById('quickAdd').addEventListener('click', openModal);
document.getElementById('addTask').addEventListener('click', openModal);
document.getElementById('closeModal').addEventListener('click', closeModal);
modal.querySelector('.modal-backdrop').addEventListener('click', closeModal);
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') closeModal();
});

quickForm.addEventListener('submit', (event) => {
    event.preventDefault();
    const data = new FormData(quickForm);
    const priority = data.get('priority');
    const category = data.get('category');
    const priorityClass = priority === 'High' ? 'priority-high' : priority === 'Low' ? 'priority-low' : 'priority-medium';
    const tagClass = category === 'Personal' ? 'tag-green' : category === 'University' ? 'tag-blue' : category === 'Work' ? 'tag-coral' : 'tag-purple';
    const task = document.createElement('label');
    task.className = 'task-row';
    task.innerHTML = `<input type="checkbox"><span class="checkmark"></span><span class="task-content"><strong>${escapeHtml(data.get('title'))}</strong><small><span class="tag ${tagClass}">${category}</span> Due today</small></span><span class="task-priority ${priorityClass}">${priority}</span>`;
    taskList.append(task);
    task.querySelector('input').addEventListener('change', (event) => {
        task.classList.toggle('completed', event.target.checked);
        task.querySelector('.checkmark').textContent = event.target.checked ? '✓' : '';
    });
    quickForm.reset();
    closeModal();
});

const screenCopy = {
    dashboard: ['YOUR PERSONAL MEMORY BANK', 'Good morning, Aditya.', 'A clear mind starts with a clear place for everything.'],
    tasks: ['AGENDA WORKSPACE', 'Tasks & Agenda', 'Keep every commitment visible and moving.'],
    notes: ['PERSONAL KNOWLEDGE BASE', 'Notes & Knowledge', 'Capture context before the details disappear.'],
    finance: ['MONEY, WITH CLARITY', 'Finance Tracker', 'See your balance, goals, and spending in one calm view.'],
    memories: ['YOUR MEMORY LOG', 'Memories', 'Keep the stories, ideas, and works that stay with you.']
};

function showScreen(screen) {
    const activeScreen = screenCopy[screen] ? screen : 'dashboard';
    const [eyebrow, title, description] = screenCopy[activeScreen];
    document.body.dataset.screen = activeScreen;
    document.querySelectorAll('.nav-item[data-view]').forEach((nav) => nav.classList.toggle('active', nav.dataset.view === activeScreen));
    document.querySelectorAll('.screen-dashboard, .screen-tasks, .screen-notes, .screen-finance, .screen-memories').forEach((element) => {
        const matches = element.classList.contains(`screen-${activeScreen}`);
        element.classList.toggle('screen-hidden', !matches);
    });
    document.querySelector('.content-grid').classList.toggle('screen-hidden', ['finance', 'memories'].includes(activeScreen));
    const screenHeading = document.getElementById('screenHeading');
    screenHeading.classList.toggle('hidden', activeScreen === 'dashboard');
    document.getElementById('screenEyebrow').textContent = eyebrow;
    document.getElementById('screenTitle').textContent = title;
    document.getElementById('screenDescription').textContent = description;
    window.history.replaceState(null, '', `#${activeScreen}`);
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

document.querySelectorAll('[data-view]').forEach((item) => {
    item.addEventListener('click', () => showScreen(item.dataset.view));
});

window.addEventListener('hashchange', () => showScreen(window.location.hash.slice(1)));
showScreen(window.location.hash.slice(1) || 'dashboard');

document.querySelectorAll('.task-row input').forEach((checkbox) => {
    checkbox.addEventListener('change', (event) => {
        const row = event.target.closest('.task-row');
        row.classList.toggle('completed', event.target.checked);
        row.querySelector('.checkmark').textContent = event.target.checked ? '✓' : '';
    });
});

document.getElementById('searchToggle').addEventListener('click', () => {
    searchBar.classList.remove('hidden');
    globalSearch.focus();
});
document.getElementById('closeSearch').addEventListener('click', () => {
    searchBar.classList.add('hidden');
    globalSearch.value = '';
    filterTasks('');
});
globalSearch.addEventListener('input', (event) => filterTasks(event.target.value));

function filterTasks(query) {
    const normalized = query.toLowerCase();
    document.querySelectorAll('#taskList .task-row').forEach((task) => {
        task.style.display = task.textContent.toLowerCase().includes(normalized) ? 'flex' : 'none';
    });
}

document.getElementById('newNote').addEventListener('click', () => {
    const note = document.querySelector('.note-list');
    const item = document.createElement('article');
    item.className = 'note-item';
    item.innerHTML = '<span class="note-type type-idea">NEW</span><h3>Untitled note</h3><p>Start capturing the thought while it is still fresh.</p><time>Just now</time>';
    note.prepend(item);
    item.querySelector('h3').focus?.();
});

function escapeHtml(value) {
    return value.replace(/[&<>'"]/g, (character) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[character]));
}
