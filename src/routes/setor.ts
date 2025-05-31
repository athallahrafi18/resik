import express from "express";
import { submitSetoran, getSetoranList, getSetoranById, updateSetoranStatus, updateSetoran } from "../controllers/setor_controller";
import { authenticate } from '../middleware/authMiddleware';

const router = express.Router();

router.post("/setor", authenticate, submitSetoran);
router.get("/setoran", getSetoranList);
router.get("/setoran/:id", getSetoranById);
router.patch("/setoran/:id/status", updateSetoranStatus);
router.put("/setoran/:id", updateSetoran);

export default router;
