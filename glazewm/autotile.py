import asyncio
import websockets
import json

async def main():
    uri = "ws://localhost:6123"
    async with websockets.connect(uri) as websocket:
        # Subscribe to window and focus events
        await websocket.send("sub -e window_managed")
        await websocket.send("sub -e focus_changed")

        while True:
            response = await websocket.recv()
            json_response = json.loads(response)

            if json_response.get("messageType") == "event_subscription":
                data = json_response.get('data', {})
                # Fetch dimensions of the active window
                window_data = data.get('managedWindow') or data.get('focusedContainer')

                if window_data:
                    width = window_data.get('width')
                    height = window_data.get('height')

                    if width and height:
                        # Dwindle logic: split along the longest axis
                        if width > height:
                            await websocket.send('c set-tiling-direction horizontal')
                        else:
                            await websocket.send('c set-tiling-direction vertical')

if __name__ == "__main__":
    asyncio.run(main())
