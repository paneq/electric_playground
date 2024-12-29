import { useState } from 'react'
import './App.css'

const handleSubmit = async (event, taskName, setTaskName) => {
  event.preventDefault()
  const response = await fetch('/tasks', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ task: { name: taskName, done: false } }),
  })
  if (response.ok) {
    const newTask = await response.json()
    console.log('Task created:', newTask)
    setTaskName('') // Clear the input field after successful submission
  } else {
    console.error('Failed to create task')
  }
}

function App() {
  const [taskName, setTaskName] = useState('')

  return (
    <div>
      <form onSubmit={(event) => handleSubmit(event, taskName, setTaskName)}>
        <input
          type="text"
          value={taskName}
          onChange={(e) => setTaskName(e.target.value)}
          placeholder="Task name"
        />
        <button type="submit">Create Task</button>
      </form>
    </div>
  )
}

export default App
