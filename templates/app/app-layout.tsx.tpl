// src/app/layout.tsx — {{PROJECT_NAME}}
// pages/app ne fait QUE le routage : les sections d'écran vivent dans src/views/.
import type { ReactNode } from 'react'

export const metadata = {
  title: '{{PROJECT_NAME}}',
  description: '{{PROJECT_DESC}}',
}

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  )
}
