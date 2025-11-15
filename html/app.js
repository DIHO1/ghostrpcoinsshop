const { createApp } = Vue

createApp({
    data() {
        return {
            visible: false,
            balance: 0,
            hero: {},
            layout: { featured: [], categories: [] },
            currency: { icon: '👻', short: 'GC' },
            images: { base: '', extension: '', fallback: '' },
            phrases: {},
            items: {},
            activity: [],
            activityEnabled: false,
            selectedCategory: null,
            selected: null,
            crate: null,
            event: null,
            countdown: '--:--',
            countdownTicker: null
        }
    },
    computed: {
        heroStyle() {
            const bg = typeof this.hero.background === 'string' ? this.hero.background : ''
            const gradientA = this.currency && this.currency.gradient && typeof this.currency.gradient[0] === 'string'
                ? this.currency.gradient[0]
                : '#755efc'
            const gradientB = this.currency && this.currency.gradient && typeof this.currency.gradient[1] === 'string'
                ? this.currency.gradient[1]
                : '#37e2ff'

            const gradientColorA = gradientA && gradientA.includes && (gradientA.includes('gradient') || gradientA.includes('url('))
                ? '#755efc'
                : gradientA
            const gradientColorB = gradientB && gradientB.includes && (gradientB.includes('gradient') || gradientB.includes('url('))
                ? '#37e2ff'
                : gradientB

            const ensureRgba = (value, alpha) => {
                if (!value || typeof value !== 'string') {
                    return value
                }
                if (value.startsWith('#')) {
                    let hex = value.slice(1)
                    if (hex.length === 3) {
                        hex = hex.split('').map((c) => c + c).join('')
                    }
                    const r = parseInt(hex.slice(0, 2), 16)
                    const g = parseInt(hex.slice(2, 4), 16)
                    const b = parseInt(hex.slice(4, 6), 16)
                    return `rgba(${r}, ${g}, ${b}, ${alpha})`
                }
                if (value.startsWith('rgb')) {
                    const parts = value
                        .replace(/rgba?\(/, '')
                        .replace(/\)/, '')
                        .split(',')
                        .map((p) => p.trim())
                    if (parts.length >= 3) {
                        const [r, g, b] = parts
                        return `rgba(${r}, ${g}, ${b}, ${alpha})`
                    }
                    return value
                }
                return value
            }

            const accentSourceA = gradientA && gradientA.includes && (gradientA.includes('gradient') || gradientA.includes('url('))
                ? '#755efc'
                : gradientA
            const accentSourceB = gradientB && gradientB.includes && (gradientB.includes('gradient') || gradientB.includes('url('))
                ? '#37e2ff'
                : gradientB

            const accentA = ensureRgba(accentSourceA, 0.85) || 'rgba(117, 94, 252, 0.85)'
            const accentB = ensureRgba(accentSourceB, 0.95) || 'rgba(55, 226, 255, 0.95)'
            const overlayB = ensureRgba(accentSourceB, 0.65)

            const style = {
                '--hero-accent-a': accentA,
                '--hero-accent-b': accentB
            }

            if (!bg) {
                style.backgroundImage = `linear-gradient(135deg, ${gradientColorA}, ${gradientColorB})`
                return style
            }

            if (bg.indexOf('linear-gradient') === 0 || bg.indexOf('radial-gradient') === 0) {
                style.backgroundImage = bg
                return style
            }

            if (bg.indexOf('url(') === 0) {
                style.backgroundImage = bg
                return style
            }

            style.backgroundImage = `linear-gradient(135deg, ${gradientColorA}, ${overlayB}), url(${bg})`
            return style
        },
        categoryItems() {
            const categories = (this.layout && Array.isArray(this.layout.categories)) ? this.layout.categories : []
            const category = categories.find(cat => cat.id === this.selectedCategory)
            if (!category) {
                return []
            }
            const items = Array.isArray(category.items) ? category.items : []
            return items.map(id => {
                const base = this.items[id] || {}
                return Object.assign({ id: id }, base)
            })
        },
        eventCountdown() {
            return this.countdown
        }
    },
    watch: {
        visible: {
            immediate: true,
            handler(value) {
                this.applyVisibilityClass(value)
            }
        }
    },
    methods: {
        applyVisibilityClass(state) {
            const className = 'ghost-market-visible'
            const targets = [document.body, document.documentElement]
            targets.forEach((element) => {
                if (!element) {
                    return
                }
                if (state) {
                    element.classList.add(className)
                } else {
                    element.classList.remove(className)
                }
            })
        },
        buildPropAsset(name) {
            if (!name) {
                return ''
            }
            const settings = this.images || {}
            const base = typeof settings.base === 'string' ? settings.base.trim() : ''
            const extension = typeof settings.extension === 'string' ? settings.extension : ''
            if (!base) {
                return ''
            }
            const sanitizedBase = base.endsWith('/') ? base.slice(0, -1) : base
            const normalized = String(name)
                .toLowerCase()
                .replace(/[^a-z0-9_/-]/g, '')
            return `${sanitizedBase}/${normalized}${extension}`
        },
        resolveArtwork(item) {
            if (!item) {
                return ''
            }
            if (item.image && typeof item.image === 'string' && item.image.trim() !== '') {
                return item.image
            }
            if (item.artwork && typeof item.artwork === 'string' && item.artwork.trim() !== '') {
                return item.artwork
            }
            const propSource = item.prop || item.weapon || item.model
            if (propSource) {
                const asset = this.buildPropAsset(propSource)
                if (asset) {
                    return asset
                }
            }
            if (this.images && typeof this.images.fallback === 'string' && this.images.fallback.trim() !== '') {
                return this.images.fallback
            }
            return ''
        },
        artworkStyles(item) {
            const asset = this.resolveArtwork(item)
            if (!asset) {
                return {
                    backgroundImage: 'linear-gradient(160deg, rgba(16, 18, 46, 0.96), rgba(9, 12, 34, 0.9))'
                }
            }
            if (asset.startsWith && (asset.startsWith('linear-gradient') || asset.startsWith('radial-gradient'))) {
                return { backgroundImage: asset }
            }
            if (asset.startsWith && asset.startsWith('url(')) {
                return { backgroundImage: asset }
            }
            return {
                backgroundImage: `linear-gradient(180deg, rgba(5, 7, 22, 0.18), rgba(5, 7, 22, 0.78)), url(${asset})`
            }
        },
        formatBalance(value) {
            const number = Number(value) || 0
            return `${number.toLocaleString('pl-PL')} ${this.currency.short}`
        },
        selectCategory(categoryId) {
            this.selectedCategory = categoryId
        },
        selectItem(itemId) {
            if (!itemId) return
            const base = this.items[itemId]
            let itemData = base
            if (!itemData) {
                const featuredList = (this.layout && Array.isArray(this.layout.featured)) ? this.layout.featured : []
                itemData = featuredList.find(card => card.id === itemId)
            }
            if (!itemData) return
            this.selected = Object.assign({ id: itemId }, itemData)
        },
        purchase(itemId) {
            if (!itemId) return
            fetch(`https://${GetParentResourceName()}/ghostmarket:purchase`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ itemId })
            })
            this.selected = null
        },
        anonymize(identifier) {
            if (!identifier || typeof identifier !== 'string') {
                return 'Anonim'
            }
            if (identifier.length <= 6) {
                return identifier
            }
            return identifier.slice(0, 3) + '***' + identifier.slice(-3)
        },
        resolveItemLabel(itemId) {
            const item = this.items[itemId]
            return item && item.label ? item.label : itemId
        },
        formatDate(value) {
            if (!value) return ''
            const date = new Date(value)
            if (Number.isNaN(date.getTime())) {
                return ''
            }
            return date.toLocaleString('pl-PL', { hour12: false })
        },
        close() {
            this.visible = false
            this.stopTimer()
            this.selected = null
            this.crate = null
            fetch(`https://${GetParentResourceName()}/ghostmarket:close`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: '{}'
            })
        },
        startTimer() {
            this.stopTimer()
            if (!this.event || !this.event.expires) {
                return
            }
            const update = () => {
                const now = new Date()
                const expires = new Date(this.event.expires)
                const diff = expires - now
                if (diff <= 0) {
                    this.countdown = '00:00:00'
                    this.stopTimer()
                    return
                }
                const totalSeconds = Math.floor(diff / 1000)
                const hours = String(Math.floor(totalSeconds / 3600)).padStart(2, '0')
                const minutes = String(Math.floor((totalSeconds % 3600) / 60)).padStart(2, '0')
                const seconds = String(totalSeconds % 60).padStart(2, '0')
                this.countdown = `${hours}:${minutes}:${seconds}`
            }
            update()
            this.countdownTicker = setInterval(update, 1000)
        },
        stopTimer() {
            if (this.countdownTicker) {
                clearInterval(this.countdownTicker)
                this.countdownTicker = null
            }
        }
    },
    mounted() {
        window.addEventListener('message', (event) => {
            const payload = event.data || {}
            const action = payload.action
            const data = payload.data || {}
            if (!action) {
                return
            }

            switch (action) {
                case 'open': {
                    const config = data.config || {}
                    this.visible = true
                    this.balance = data.balance || 0
                    this.hero = config.hero || {}
                    this.layout = config.layout || { featured: [], categories: [] }
                    this.currency = config.currency || this.currency
                    this.images = Object.assign({}, this.images, config.images || {})
                    this.items = config.items || {}
                    this.phrases = config.phrases || {}
                    const activityConfig = config.activity || {}
                    this.activityEnabled = !!activityConfig.enabled
                    this.activity = Array.isArray(data.activity) ? data.activity : []
                    const categories = (this.layout && Array.isArray(this.layout.categories)) ? this.layout.categories : []
                    this.selectedCategory = categories.length > 0 ? categories[0].id : null
                    this.event = data.event
                    this.selected = null
                    this.crate = null
                    this.startTimer()
                    break
                }
                case 'close':
                    this.visible = false
                    this.stopTimer()
                    break
                case 'balance':
                    this.balance = data.balance || 0
                    break
                case 'event':
                    this.event = data
                    this.startTimer()
                    break
                case 'crate':
                    this.crate = data
                    break
            }
        })

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.visible) {
                this.close()
            }
        })

        window.addEventListener('beforeunload', () => {
            this.applyVisibilityClass(false)
        })

        fetch(`https://${GetParentResourceName()}/ghostmarket:ready`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: '{}'
        })
    }
}).mount('#app')
