import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./styles.css";
import "./responsive.css";
import "./design-system.css";
import { ThemeProvider } from "./Theme";
createRoot(document.getElementById("root")!).render(<React.StrictMode><ThemeProvider><App /></ThemeProvider></React.StrictMode>);