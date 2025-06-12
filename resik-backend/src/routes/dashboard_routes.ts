import express from "express";
import { getDashboardSummary } from "../controllers/dashboard_controller";

const router = express.Router();

router.get("/dashboard-summary", getDashboardSummary);

export default router;
