import clsx from 'clsx'

import { Icon } from '@/components/Icon'

const styles = {
  note: {
    container:
      'bg-awesome-50 dark:bg-awesome-800/60 dark:ring-1 dark:ring-awesome-300/10',
    title: 'text-awesome-900 dark:text-awesome-400',
    body: 'text-awesome-800 [--tw-prose-background:theme(colors.awesome.50)] prose-a:text-awesome-900 prose-code:text-awesome-900 dark:text-awesome-200 dark:prose-code:text-awesome-200',
  },
  warning: {
    container:
      'bg-amber-50/20 dark:bg-awesome-800/30 ring-1 ring-awesome-200/30',
    title: 'text-amber-900 dark:text-amber-500',
    body: 'text-amber-800 [--tw-prose-underline:theme(colors.amber.400)] [--tw-prose-background:theme(colors.amber.50)] prose-a:text-amber-900 prose-code:text-amber-900 dark:text-awesome-200 dark:[--tw-prose-underline:theme(colors.awesome.700)] dark:prose-code:text-awesome-200',
  },
}

const icons = {
  note: (props) => <Icon icon="lightbulb" {...props} />,
  warning: (props) => <Icon icon="warning" color="amber" {...props} />,
}

export function Callout({ type = 'note', title, children }) {
  let IconComponent = icons[type]

  return (
    <div className={clsx('my-8 flex rounded-lg p-6', styles[type].container)}>
      <IconComponent className="h-8 w-8 flex-none" />
      <div className="ml-4 flex-auto">
        <p className={clsx('m-0 font-display text-xl', styles[type].title)}>
          {title}
        </p>
        <div className={clsx('prose mt-2.5', styles[type].body)}>
          {children}
        </div>
      </div>
    </div>
  )
}
