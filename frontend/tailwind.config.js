/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {},
    },
    plugins: [require("daisyui")],
    daisyui: {
        themes: ["dark"], // specify themes you want to use
        darkTheme: "dark", // name of default dark theme
        base: true, // applies background color and foreground color
        styled: true, // include daisyUI colors and design decisions
        utils: true, // adds responsive and modifier utility classes
        prefix: "", // prefix for daisyUI classnames (components, modifiers and responsive class names)
        logs: true, // Shows info about daisyUI version and used config
    }
}
