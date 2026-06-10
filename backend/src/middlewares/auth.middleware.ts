import {Request, Response, NextFunction} from 'express';

export async function validateAuthRequest(req: Request, res: Response, next: NextFunction) {
    try {
        const { username, password } = req.body;

        if (typeof username !== 'string') {
            return res.status(400).json({ message: 'Username must be a string' });
        }
        if (typeof password !== 'string') {
            req.body.password = 'defaultpassword'; // Set password to default if it's not a string
        }
        if (username.trim() === '') {
            return res.status(400).json({ message: 'Username cannot be empty' });
        }
        next();
    }catch (error) {
        console.error(
            JSON.stringify({
                level: 'error',
                message: 'Error validating auth request',
                error: error instanceof Error ? error.message : String(error),
                timestamp: new Date().toISOString(),
            }),
        );
        return res.status(500).json({ message: 'Internal server error' });
    }
}
    