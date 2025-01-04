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

function Task({ task, comments, onCheckboxChange }) {
    return (
        <div className="space-y-2">
            <div className="flex items-center space-x-2 p-2 bg-base-200 rounded-lg shadow">
                <input
                    type="checkbox"
                    checked={task.done}
                    className="checkbox checkbox-primary"
                    onChange={(event) => onCheckboxChange(task, event)}
                />
                <div className="flex-1">
                    <span className="text-lg">{task.name}</span>
                </div>
            </div>

            {comments.length > 0 && (
                <div className="space-y-1">
                    {comments.map(comment => (
                        <Comment key={comment.id.toString()} comment={comment} />
                    ))}
                </div>
            )}
        </div>
    );
}

function Comment({ comment }) {
    return (
        <div className="ml-8 p-2 bg-base-100 rounded-md text-sm">
            <div className="text-base-content/70">
                {comment.body}
            </div>
        </div>
    );
}

const TasksList = memo(() => {
    const { data: taskData, isLoading: isLoadingTasks } = useShape({
        url: `http://localhost/electric/v1/shape`,
        params: {
            table: `tasks`,
            where: `user_id = ${currentUserId}`
        }
    })
    // console.log(taskData)
    const taskIds = taskData.map((task) => task.id.toString())
    const { data: dataComments } = useShape({
        url: `http://localhost/electric/v1/shape`,
        params: {
            table: `comments`,
            where: `user_id = ${currentUserId} AND (task_id IN (${taskIds.join(',')}))`
        }
    })
    // console.log(dataComments)

    return (
        <div className="space-y-2">
            {taskData.map((task) => {
                const taskComments = dataComments.filter(comment => {
                    console.log(comment.task_id.toString(), task.id.toString());
                    return comment.task_id.toString() === task.id.toString();
                });
                console.log(taskComments);
                return (
                    <Task
                        key={task.id.toString()}
                        task={task}
                        onCheckboxChange={handleCheckboxChange}
                        comments={taskComments}
                    />
                );
            })}
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
