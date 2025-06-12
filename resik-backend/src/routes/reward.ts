import express from "express";
import { claimReward, getRewardSaldo, getAllRewardList, getRewardDetail, updateRewardStatus } from "../controllers/reward_controller";
import { authenticate } from '../middleware/authMiddleware';

const router = express.Router();

router.get("/reward/saldo", authenticate, getRewardSaldo);
router.get("/rewards", getAllRewardList);
router.get("/rewards/:id", getRewardDetail);
router.post("/reward/claim", authenticate, claimReward);
router.put("/rewards/:id/status", updateRewardStatus);

export default router;