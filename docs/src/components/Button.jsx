import Link from 'next/link'
import clsx from 'clsx'

const styles = {
  primary:
    'rounded-full bg-awesome-300 py-2 px-4 text-sm font-semibold text-awesome-900 hover:bg-awesome-200 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-awesome-300/50 active:bg-awesome-500',
  secondary:
    'rounded-full bg-awesome-800 py-2 px-4 text-sm font-medium text-white hover:bg-awesome-700 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white/50 active:text-awesome-400 border border-awesome-200/20',
}

export function Button({ variant = 'primary', className, href, ...props }) {
  className = clsx(styles[variant], className)

  return href ? (
    <Link href={href} className={className} {...props} />
  ) : (
    <button className={className} {...props} />
  )
}
