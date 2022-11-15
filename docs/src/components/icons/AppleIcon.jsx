import { DarkMode, Gradient, LightMode } from '@/components/Icon'

export function AppleIcon({ id, color }) {
  return (
    <>
      <defs>
        <Gradient
          id={`${id}-gradient`}
          color={color}
          gradientTransform="matrix(0 21 -21 0 12 11)"
        />
        <Gradient
          id={`${id}-gradient-dark`}
          color={color}
          gradientTransform="matrix(0 24.5 -24.5 0 16 5.5)"
        />
      </defs>
      <LightMode>
        <circle cx={12} cy={20} r={12} fill={`url(#${id}-gradient)`} />
        <path
          d="M24.034 28.98c-1.537 1.49-3.214 1.254-4.829.549-1.708-.721-3.276-.753-5.079 0-2.258.972-3.449.69-4.797-.549-7.65-7.885-6.522-19.894 2.163-20.333 2.117.11 3.59 1.16 4.829 1.254 1.85-.376 3.621-1.458 5.596-1.316 2.368.188 4.155 1.128 5.33 2.821-4.89 2.932-3.73 9.375.753 11.178-.894 2.352-2.054 4.687-3.982 6.412l.016-.016Zm-7.87-20.427c-.235-3.496 2.602-6.38 5.863-6.662.455 4.044-3.668 7.054-5.863 6.662Z"
          fillOpacity={0.5}
          className="fill-[var(--icon-background)] stroke-[color:var(--icon-foreground)]"
          strokeWidth={2}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </LightMode>
      <DarkMode>
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M24.034 28.98c-1.537 1.49-3.214 1.254-4.829.549-1.708-.721-3.276-.753-5.079 0-2.258.972-3.449.69-4.797-.549-7.65-7.885-6.522-19.894 2.163-20.333 2.117.11 3.59 1.16 4.829 1.254 1.85-.376 3.621-1.458 5.596-1.316 2.368.188 4.155 1.128 5.33 2.821-4.89 2.932-3.73 9.375.753 11.178-.894 2.352-2.054 4.687-3.982 6.412l.016-.016Zm-7.87-20.427c-.235-3.496 2.602-6.38 5.863-6.662.455 4.044-3.668 7.054-5.863 6.662Z"
          fill={`url(#${id}-gradient-dark)`}
        />
      </DarkMode>
    </>
  )
}
