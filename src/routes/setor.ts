import express from "express";
import { submitSetoran, getSetoranList, getSetoranById } from "../controllers/setor_controller";

const router = express.Router();

router.post("/setor", submitSetoran);
router.get("/setoran", getSetoranList);
router.get("/setoran/:id", getSetoranById);


export default router;
