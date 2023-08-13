import websockets
import asyncio
from websockets.server import serve

async def error_receiver(websocket):
    async for msg in websocket:
        print(msg)

async def main():
    async with serve(error_receiver, "localhost", 5999):
        await asyncio.Future()

asyncio.run(main())