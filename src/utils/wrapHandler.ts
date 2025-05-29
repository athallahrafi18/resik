import { Request, Response, NextFunction, RequestHandler } from 'express';

// Fungsi ini menerima controller biasa (tanpa next), dan otomatis tangani error
export const wrapHandler = (
  handler: (req: Request, res: Response) => any
): RequestHandler => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = handler(req, res);
      if (result instanceof Promise) {
        result.catch(next); // tangkap error async
      }
    } catch (error) {
      next(error); // tangkap error sync
    }
  };
};
