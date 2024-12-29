import { useState, memo } from 'react'
import './App.css'
import { useShape } from '@electric-sql/react'

const currentUserId = 1

const handleCheckboxChange = async (task, event) => {
    event.preventDefault()
    const updatedTask = {
        done: event.target.checked
    }
    const response = await fetch(`/tasks/${task.id}`, {
        method: 'PATCH',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ task: updatedTask }),
    })
    if (response.ok) {
        console.log('Task updated:', updatedTask)
    } else {
        console.error('Failed to update task')
    }
}

function Task({ task, onCheckboxChange }) {
    return (
        <div className="flex items-center space-x-2 p-2 bg-base-200 rounded-lg shadow">
            <input
                type="checkbox"
                checked={task.done}
                className="checkbox checkbox-primary"
                onChange={(event) => onCheckboxChange(task, event)}
            />
            <span className="text-lg">{task.name}</span>
        </div>
    )
}

const TasksList = memo(() => {
    const { data } = useShape({
        url: `http://localhost/electric/v1/shape`,
        params: {
            table: `tasks`,
            where: `user_id = ${currentUserId}`
        }
    })

    console.log(data)
    return (
        <div className="space-y-2">
            {data.map((task) => (
                <Task key={task.id.toString()} task={task} onCheckboxChange={handleCheckboxChange} />
            ))}
        </div>
    )
})

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
        <div className="p-4 max-w-md mx-auto">
            <form onSubmit={(event) => handleSubmit(event, taskName, setTaskName)} className="flex space-x-2 mb-4">
                <input
                    type="text"
                    value={taskName}
                    onChange={(e) => setTaskName(e.target.value)}
                    placeholder="Task name"
                    className="input input-bordered w-full"
                />
                <button type="submit" className="btn btn-primary">Create Task</button>
            </form>

            <TasksList />
        </div>
    )
}

export default App
