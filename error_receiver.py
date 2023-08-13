import json
import websockets
import asyncio
from websockets.server import serve

async def error_receiver(websocket):
    try:
        async for msg in websocket:
            msg = json.loads(msg)
            print('------------------')
            print('Error received:')
            print('Error:', msg['error'])
            print('Message:', msg['message'])
            print('Stacktrace:', msg['stackTrace'])
            print('------------------')
    except websockets.exceptions.ConnectionClosed:
        pass
    except Exception as e:
        print(e)

async def main():
    async with serve(error_receiver, "localhost", 5999):
        await asyncio.Future()

asyncio.run(main())