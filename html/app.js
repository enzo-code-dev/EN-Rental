/*
███████╗███╗   ██╗███████╗ ██████╗      ██████╗ ██████╗ ██████╗ ███████╗
██╔════╝████╗  ██║╚══███╔╝██╔═══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
█████╗  ██╔██╗ ██║  ███╔╝ ██║   ██║    ██║     ██║   ██║██║  ██║█████╗
██╔══╝  ██║╚██╗██║ ███╔╝  ██║   ██║    ██║     ██║   ██║██║  ██║██╔══╝
███████╗██║ ╚████║███████╗╚██████╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗
╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝

               DISCORD • https://discord.gg/HPEAWNB52w
*/

const $ = (id) => document.getElementById(id);

const menuRoot = $('menuRoot');
const vehicleList = $('vehicleGrid');
const categoryFilters = $('categoryFilters');
const emptyState = $('emptyState');
const timeOptions = $('timeOptions');
const rentButton = $('rentButton');
const closeButton = $('closeButton');
const interactionPrompt = $('interactionPrompt');
const notifications = $('notifications');
const rentalTimers = $('rentalTimers');

const state = {
    open: false,
    vehicles: [],
    times: [],
    category: 'all',
    vehicle: null,
    minutes: null,
    text: {},
    ui: {},
    timers: new Map()
};

async function nui(eventName, data = {}) {
    try {
        const response = await fetch(`https://${GetParentResourceName()}/${eventName}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        return await response.json();
    } catch (error) {
        return { ok: false };
    }
}

function money(value) {
    const amount = Number(value) || 0;
    const currency = state.ui.Currency || '$';
    const locale = state.ui.Locale || 'en-US';

    try {
        return `${currency}${new Intl.NumberFormat(locale).format(amount)}`;
    } catch (error) {
        return `${currency}${Math.round(amount)}`;
    }
}

function applyTheme() {
    const theme = state.ui.Theme || {};
    const variables = {
        accent: '--accent',
        accentHover: '--accent-hover',
        accentSoft: '--accent-soft',
        background: '--background',
        panel: '--panel',
        surface: '--surface',
        surfaceHover: '--surface-hover',
        footer: '--footer',
        border: '--border',
        borderStrong: '--border-strong',
        text: '--text',
        muted: '--muted',
        mutedDark: '--muted-dark',
        danger: '--danger',
        success: '--success'
    };

    for (const [key, cssName] of Object.entries(variables)) {
        const value = theme[key];
        if (typeof value === 'string' && value.trim()) {
            document.documentElement.style.setProperty(cssName, value.trim());
        }
    }
}

function setText() {
    const t = state.text;
    const ui = state.ui;

    $('brandName').textContent = ui.Brand || 'ENZO RENTAL';
    $('creditText').textContent = ui.Credit || 'ENZO CODE';
    $('discordText').textContent = (ui.Discord || 'https://discord.gg/HPEAWNB52w').replace(/^https?:\/\//, '');
    $('menuTitle').textContent = t.menuTitle || 'Rent a vehicle';
    $('menuSubtitle').textContent = t.menuSubtitle || 'Choose a vehicle and rental duration.';
    $('durationLabel').textContent = t.durationLabel || 'Rental duration';
    $('totalLabel').textContent = t.totalLabel || 'Total price';
    $('rentButtonText').textContent = t.rentButton || 'Rent vehicle';
    $('paymentHint').textContent = t.paymentHint || 'Payment account is selected automatically.';
    $('selectedVehicleLabel').textContent = t.selectedVehicle || 'Selected vehicle';
    $('priceRateLabel').textContent = t.priceRate || 'Price rate';
    $('seatsLabel').textContent = t.seats || 'Seats';
    emptyState.textContent = t.noVehicles || 'No vehicles are available in this category.';
    closeButton.setAttribute('aria-label', t.closeButton || 'Close');
}

function categories() {
    return [...new Set(state.vehicles.map((vehicle) => vehicle.category).filter(Boolean))];
}

function renderCategories() {
    categoryFilters.replaceChildren();
    const items = [
        { key: 'all', label: state.text.allCategories || 'All' },
        ...categories().map((category) => ({ key: category, label: category }))
    ];

    for (const item of items) {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'category-filter';
        button.classList.toggle('is-selected', state.category === item.key);
        button.textContent = item.label;
        button.addEventListener('click', () => {
            state.category = item.key;
            renderCategories();
            renderVehicles();
        });
        categoryFilters.appendChild(button);
    }
}

function visibleVehicles() {
    if (state.category === 'all') return state.vehicles;
    return state.vehicles.filter((vehicle) => vehicle.category === state.category);
}

function renderVehicles() {
    vehicleList.replaceChildren();
    const vehicles = visibleVehicles();
    const countWord = vehicles.length === 1
        ? (state.text.vehicleCount || 'vehicle')
        : (state.text.vehiclesCount || 'vehicles');

    $('vehicleCount').textContent = `${vehicles.length} ${countWord}`;
    emptyState.classList.toggle('is-visible', vehicles.length === 0);

    for (const vehicle of vehicles) {
        const row = document.createElement('button');
        row.type = 'button';
        row.className = 'vehicle-row';
        row.classList.toggle('is-selected', state.vehicle?.model === vehicle.model);

        const main = document.createElement('div');
        main.className = 'vehicle-main';

        const titleLine = document.createElement('div');
        titleLine.className = 'vehicle-title-line';

        const name = document.createElement('span');
        name.className = 'vehicle-name';
        name.textContent = vehicle.label || vehicle.model;

        const category = document.createElement('span');
        category.className = 'vehicle-category';
        category.textContent = vehicle.category || state.text.vehicleLabel || 'Vehicle';

        const description = document.createElement('p');
        description.className = 'vehicle-description';
        description.textContent = vehicle.description || '';

        titleLine.append(name, category);
        main.append(titleLine, description);

        const side = document.createElement('div');
        side.className = 'vehicle-side';

        const price = document.createElement('span');
        price.className = 'vehicle-price';
        price.innerHTML = `<strong>${money(vehicle.price)}</strong><small>${state.text.perMinute || '/ min'}</small>`;

        const seats = document.createElement('span');
        seats.className = 'vehicle-seats';
        seats.textContent = vehicle.seats ? `${vehicle.seats} ${state.text.seats || 'seats'}` : '—';

        side.append(price, seats);
        row.append(main, side);
        row.addEventListener('click', () => selectVehicle(vehicle.model));
        vehicleList.appendChild(row);
    }
}

function renderTimes() {
    timeOptions.replaceChildren();

    for (const rawMinutes of state.times) {
        const minutes = Number(rawMinutes);
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'time-chip';
        button.classList.toggle('is-selected', state.minutes === minutes);
        button.innerHTML = `<strong>${minutes}</strong><small>${state.text.minute || 'min'}</small>`;
        button.addEventListener('click', () => {
            state.minutes = minutes;
            renderTimes();
            refreshBooking();
        });
        timeOptions.appendChild(button);
    }
}

function selectVehicle(model) {
    state.vehicle = state.vehicles.find((vehicle) => vehicle.model === model) || null;
    renderVehicles();
    refreshBooking();
}

function refreshBooking() {
    const vehicle = state.vehicle;
    const minutes = state.minutes;
    const noSelection = state.text.noSelection || 'Not selected';

    $('selectedVehicleValue').textContent = vehicle ? (vehicle.label || vehicle.model) : noSelection;
    $('selectedCategory').textContent = vehicle ? (vehicle.category || state.text.vehicleLabel || 'Vehicle') : '—';
    $('selectedVehicleDescription').textContent = vehicle
        ? (vehicle.description || '')
        : (state.text.chooseVehicleHint || 'Choose a vehicle from the list.');
    $('selectedVehicleRate').textContent = vehicle
        ? `${money(vehicle.price)} ${state.text.perMinute || '/ min'}`
        : '—';
    $('selectedVehicleSeats').textContent = vehicle?.seats
        ? `${vehicle.seats} ${state.text.seats || 'seats'}`
        : '—';
    $('selectedDurationValue').textContent = minutes
        ? `${minutes} ${state.text.minute || 'min'}`
        : noSelection;
    $('totalPrice').textContent = vehicle && minutes ? money(vehicle.price * minutes) : money(0);
    rentButton.disabled = !(vehicle && minutes);
}

function openMenu(data) {
    state.open = true;
    state.vehicles = Array.isArray(data.vehicles)
        ? data.vehicles.map((vehicle) => ({ ...vehicle, price: Number(vehicle.price ?? data.pricePerMinute ?? 0) }))
        : [];
    state.times = Array.isArray(data.times) ? data.times : [];
    state.text = data.text || {};
    state.ui = data.ui || {};
    state.category = 'all';
    state.vehicle = null;
    state.minutes = null;

    applyTheme();
    setText();
    renderCategories();
    renderVehicles();
    renderTimes();
    refreshBooking();

    interactionPrompt.classList.remove('is-visible');
    menuRoot.classList.add('is-visible');
    menuRoot.setAttribute('aria-hidden', 'false');
}

function closeMenuVisual() {
    state.open = false;
    menuRoot.classList.remove('is-visible');
    menuRoot.setAttribute('aria-hidden', 'true');
}

async function requestClose() {
    if (!state.open) return;
    closeMenuVisual();
    await nui('close');
}

function showNotification(data) {
    const type = ['success', 'error', 'info'].includes(data.type) ? data.type : 'info';
    const titles = {
        success: state.text.notificationSuccess || 'Success',
        error: state.text.notificationError || 'Error',
        info: state.text.notificationInfo || 'Notice'
    };

    const item = document.createElement('div');
    item.className = `notification ${type}`;

    const title = document.createElement('strong');
    title.textContent = data.title || titles[type];

    const message = document.createElement('p');
    message.textContent = data.message || '';

    item.append(title, message);
    notifications.appendChild(item);

    window.setTimeout(() => {
        item.classList.add('is-leaving');
        window.setTimeout(() => item.remove(), 120);
    }, 4000);
}

function formatTime(seconds) {
    const value = Math.max(0, Math.floor(seconds));
    const minutes = String(Math.floor(value / 60)).padStart(2, '0');
    const secs = String(value % 60).padStart(2, '0');
    return `${minutes}:${secs}`;
}

function removeRentalTimer(id) {
    const key = String(id);
    const timer = state.timers.get(key);
    if (!timer) return;
    timer.element.remove();
    state.timers.delete(key);
}

function updateRentalTimer(id) {
    const timer = state.timers.get(String(id));
    if (!timer) return;
    const remaining = Math.max(0, Math.ceil((timer.endsAt - Date.now()) / 1000));
    timer.element.querySelector('.timer-topline strong').textContent = formatTime(remaining);
}

function addRentalTimer(data) {
    const id = String(data.id);
    removeRentalTimer(id);

    const element = document.createElement('div');
    element.className = 'rental-timer';
    element.innerHTML = `
        <div class="timer-topline"><span></span><strong>00:00</strong></div>
        <div class="timer-details"><span class="timer-vehicle"></span><span class="timer-plate"></span></div>
    `;
    element.querySelector('.timer-topline span').textContent = data.timerLabel || 'ENZO RENTAL';
    element.querySelector('.timer-vehicle').textContent = data.label || 'Rental';
    element.querySelector('.timer-plate').textContent = data.plate || '';
    rentalTimers.appendChild(element);

    state.timers.set(id, {
        element,
        endsAt: Date.now() + (Number(data.duration) * 1000)
    });
    updateRentalTimer(id);
}

rentButton.addEventListener('click', async () => {
    if (!state.vehicle || !state.minutes || rentButton.disabled) return;

    rentButton.disabled = true;
    const result = await nui('rent', {
        model: state.vehicle.model,
        minutes: state.minutes
    });

    if (!result?.ok) rentButton.disabled = false;
});

closeButton.addEventListener('click', requestClose);
menuRoot.addEventListener('click', (event) => {
    if (event.target === menuRoot) requestClose();
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') requestClose();
});

window.addEventListener('message', ({ data }) => {
    if (!data || typeof data.action !== 'string') return;

    if (data.action === 'openMenu') openMenu(data);
    if (data.action === 'closeMenu') closeMenuVisual();
    if (data.action === 'notify') showNotification(data);
    if (data.action === 'rentalStart') addRentalTimer(data);
    if (data.action === 'rentalStop') removeRentalTimer(data.id);

    if (data.action === 'prompt') {
        $('promptText').textContent = data.text || '';
        document.querySelector('.prompt-key').textContent = data.key || 'E';
        interactionPrompt.classList.toggle('is-visible', Boolean(data.visible));
        interactionPrompt.setAttribute('aria-hidden', String(!data.visible));
    }
});

window.setInterval(() => {
    for (const id of state.timers.keys()) updateRentalTimer(id);
}, 500);
