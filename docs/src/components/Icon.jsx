import { useId } from 'react'
import clsx from 'clsx'

import { InstallationIcon } from '@/components/icons/InstallationIcon'
import { LightbulbIcon } from '@/components/icons/LightbulbIcon'
import { PluginsIcon } from '@/components/icons/PluginsIcon'
import { PresetsIcon } from '@/components/icons/PresetsIcon'
import { ThemingIcon } from '@/components/icons/ThemingIcon'
import { WarningIcon } from '@/components/icons/WarningIcon'
import { AppleIcon } from '@/components/icons/AppleIcon'
import { AndroidIcon } from '@/components/icons/AndroidIcon'
import { GitHubIcon } from '@/components/icons/GitHubIcon'

import { theme } from 'tailwind.config'

const icons = {
  installation: InstallationIcon,
  presets: PresetsIcon,
  plugins: PluginsIcon,
  theming: ThemingIcon,
  apple: AppleIcon,
  android: AndroidIcon,
  lightbulb: LightbulbIcon,
  warning: WarningIcon,
  github: GitHubIcon,
}

const colors = theme.extend.colors
const awesome = colors['awesome']

const iconStyles = {
  blue: '[--icon-foreground:theme(colors.awesome.900)] [--icon-background:theme(colors.white)]',
  amber:
    '[--icon-foreground:theme(colors.amber.900)] [--icon-background:theme(colors.amber.100)]',
}

export function Icon({ color = 'blue', icon, className, ...props }) {
  let id = useId()
  let IconComponent = icons[icon]

  return (
    <svg
      aria-hidden="true"
      viewBox={`0 0 32 32`}
      fill="none"
      className={clsx(className, iconStyles[color])}
      {...props}
    >
      <IconComponent id={id} color={color} />
    </svg>
  )
}

const gradients = {
  blue: [
    { stopColor: awesome[300] },
    { stopColor: awesome[400], offset: '.527' },
    { stopColor: awesome[500], offset: 1 },
  ],
  amber: [
    { stopColor: '#FDE68A', offset: '.08' },
    { stopColor: '#F59E0B', offset: '.837' },
  ],
}

export function Gradient({ color = 'blue', ...props }) {
  return (
    <radialGradient
      cx={0}
      cy={0}
      r={1}
      gradientUnits="userSpaceOnUse"
      {...props}
    >
      {gradients[color].map((stop, stopIndex) => (
        <stop key={stopIndex} {...stop} />
      ))}
    </radialGradient>
  )
}

export function LightMode({ className, ...props }) {
  return <g className={clsx('dark:hidden', className)} {...props} />
}

export function DarkMode({ className, ...props }) {
  return <g className={clsx('hidden dark:inline', className)} {...props} />
}
