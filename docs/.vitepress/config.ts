import { defineConfig } from 'vitepress'

const base = process.env.VITEPRESS_BASE ?? '/skill-setup-skill/'
const withBase = (path: string) => `${base}${path.replace(/^\//, '')}`

const englishSidebar = [
  {
    text: 'Guide',
    items: [
      { text: 'Export', link: '/guide/export' },
      { text: 'Restore', link: '/guide/restore' },
      { text: 'Manifest', link: '/guide/manifest' },
      { text: 'Safety', link: '/guide/safety' }
    ]
  }
]

const japaneseSidebar = [
  {
    text: 'ガイド',
    items: [
      { text: 'エクスポート', link: '/ja/guide/export' },
      { text: '復元', link: '/ja/guide/restore' },
      { text: 'マニフェスト', link: '/ja/guide/manifest' },
      { text: '安全設計', link: '/ja/guide/safety' }
    ]
  }
]

export default defineConfig({
  title: 'Skill Setup',
  description: 'Export and restore Codex skill registrations between Windows PCs.',
  base,
  cleanUrls: true,
  head: [
    ['link', { rel: 'icon', href: withBase('/favicon.svg') }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'Skill Setup' }],
    ['meta', { property: 'og:image', content: 'https://sunwood-ai-labs.github.io/skill-setup-skill/skill-setup-header.png' }]
  ],
  themeConfig: {
    logo: { src: '/favicon.svg', alt: 'Skill Setup' },
    search: {
      provider: 'local'
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/Sunwood-ai-labs/skill-setup-skill' }
    ]
  },
  locales: {
    root: {
      label: 'English',
      lang: 'en-US',
      title: 'Skill Setup',
      description: 'Export and restore Codex skill registrations between Windows PCs.',
      themeConfig: {
        nav: [
          { text: 'Guide', link: '/guide/export' },
          { text: 'Manifest', link: '/guide/manifest' },
          { text: 'Safety', link: '/guide/safety' }
        ],
        sidebar: englishSidebar
      }
    },
    ja: {
      label: '日本語',
      lang: 'ja-JP',
      title: 'Skill Setup',
      description: 'Windows PC 間で Codex skill 登録を export / restore するためのガイドです。',
      themeConfig: {
        nav: [
          { text: 'ガイド', link: '/ja/guide/export' },
          { text: 'マニフェスト', link: '/ja/guide/manifest' },
          { text: '安全設計', link: '/ja/guide/safety' }
        ],
        sidebar: japaneseSidebar
      }
    }
  }
})
