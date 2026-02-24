import { useEffect, useRef, useState } from 'react'
import { animate } from 'motion'

interface AnimatedNumberProps {
  value: number
  decimals?: number
  suffix?: string
  duration?: number
  className?: string
}

export function AnimatedNumber({ value, decimals = 0, suffix = '', duration = 0.6, className }: AnimatedNumberProps) {
  const [display, setDisplay] = useState('0')
  const prevValue = useRef(0)

  useEffect(() => {
    const controls = animate(prevValue.current, value, {
      duration,
      ease: [0.32, 0.72, 0, 1],
      onUpdate(latest) {
        setDisplay(latest.toFixed(decimals))
      },
    })
    prevValue.current = value
    return () => controls.stop()
  }, [value, decimals, duration])

  return <span className={className}>{display}{suffix}</span>
}
