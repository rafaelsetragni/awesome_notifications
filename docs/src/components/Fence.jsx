import { Fragment } from 'react'
import Highlight, { defaultProps, Prism } from 'prism-react-renderer'

// Hack to *include* other languages
// @ts-ignore
;(typeof global !== 'undefined' ? global : window).Prism = Prism
require('prismjs/components/prism-dart')
require('prismjs/components/prism-gradle')
require('prismjs/components/prism-kotlin')
require('prismjs/components/prism-java')
require('prismjs/components/prism-swift')

export function Fence({ children, language }) {
  return (
    <Highlight
      {...defaultProps}
      code={children.trimEnd()}
      language={language}
      Prism={Prism}
      /* styles={{
        languages: ['dart', 'gradle', 'xml'],
      }} */
      theme={undefined}
    >
      {({ className, style, tokens, getTokenProps }) => (
        <pre className={className} style={style}>
          <code>
            {tokens.map((line, lineIndex) => (
              <Fragment key={lineIndex}>
                {line
                  .filter((token) => !token.empty)
                  .map((token, tokenIndex) => (
                    <span key={tokenIndex} {...getTokenProps({ token })} />
                  ))}
                {'\n'}
              </Fragment>
            ))}
          </code>
        </pre>
      )}
    </Highlight>
  )
}
