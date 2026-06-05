import { AccessToken } from 'livekit-server-sdk'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const apiKey = Deno.env.get('LIVEKIT_API_KEY')
  const apiSecret = Deno.env.get('LIVEKIT_API_SECRET')

  if (!apiKey || !apiSecret) {
    return new Response(
      JSON.stringify({ error: 'LiveKit credentials not configured' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  const { roomId, participantName } = await req.json()

  const at = new AccessToken(apiKey, apiSecret, {
    identity: participantName,
    ttl: '2h',
  })

  at.addGrant({
    roomJoin: true,
    room: roomId,
    canPublish: true,
    canSubscribe: true,
  })

  const token = await at.toJwt()

  return new Response(
    JSON.stringify({ token }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
})
