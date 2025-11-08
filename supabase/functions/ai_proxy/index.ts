// @ts-nocheck
// AI Proxy Edge Function for Tempo Pilot
// Streams Azure OpenAI responses via SSE with tester cohort validation

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface RequestPayload {
  kind: 'plan' | 'replan' | 'reflect';
  messages: Array<{ role: string; content: string }>;
  availability_context?: {
    tz?: string;
    tz_offset?: string;
    day?: string;
    day_iso?: string;
    intervals?: Array<{
      start: string;
      end: string;
      minutes: number;
    }>;
  };
  metadata?: {
    device?: string;
    appVersion?: string;
  };
}

interface AzureMessage {
  role: string;
  content: string;
  tool_calls?: Array<{
    id: string;
    type: string;
    function: {
      name: string;
      arguments: string;
    };
  }>;
  tool_call_id?: string;
}

// Calendar tools available to the AI
const CALENDAR_TOOLS = [
  {
    type: "function",
    function: {
      name: "get_availability",
      description: "Get the user's free time slots for today based on their calendar. Returns actual available time blocks.",
      parameters: {
        type: "object",
        properties: {
          date: {
            type: "string",
            description: "Date to check availability for (YYYY-MM-DD format). Defaults to today if not specified."
          },
          min_duration: {
            type: "integer",
            description: "Minimum duration in minutes for free blocks. Defaults to 15 minutes."
          }
        },
        required: []
      }
    }
  },
  {
    type: "function",
    function: {
      name: "check_time_slot",
      description: "Check if a specific time slot is available in the user's calendar",
      parameters: {
        type: "object",
        properties: {
          start_time: {
            type: "string",
            description: "Start time in HH:MM format (24-hour)"
          },
          end_time: {
            type: "string",
            description: "End time in HH:MM format (24-hour)"
          },
          date: {
            type: "string",
            description: "Date to check (YYYY-MM-DD format). Defaults to today."
          }
        },
        required: ["start_time", "end_time"]
      }
    }
  }
];

// Tool execution functions
async function executeCalendarTool(
  toolName: string, 
  args: any, 
  userId: string, 
  supabase: any,
  availabilityContext?: any
): Promise<string> {
  try {
    switch (toolName) {
      case 'get_availability':
        return await getAvailability(args, userId, supabase, availabilityContext);
      case 'check_time_slot':
        return await checkTimeSlot(args, userId, supabase, availabilityContext);
      default:
        return JSON.stringify({ error: `Unknown tool: ${toolName}` });
    }
  } catch (error) {
    console.error(`Tool execution error for ${toolName}:`, error);
    return JSON.stringify({ error: `Failed to execute ${toolName}: ${error.message}` });
  }
}

async function getAvailability(
  args: any, 
  userId: string, 
  supabase: any,
  availabilityContext?: any
): Promise<string> {
  const today = new Date().toISOString().split('T')[0];
  const requestedDate = args.date || today;
  const minDuration = args.min_duration || 15;
  
  try {
    // If client provided availability context, use it
    if (availabilityContext && availabilityContext.intervals) {
      const filtered = availabilityContext.intervals.filter(
        (block: any) => block.minutes >= minDuration
      );
      
      return JSON.stringify({
        date: availabilityContext.day_iso || requestedDate,
        timezone: availabilityContext.tz || 'local',
        tz_offset: availabilityContext.tz_offset,
        generated_at: new Date().toISOString(),
        intervals: filtered,
        source: 'client_calendar'
      });
    }
    
    // Fallback: no availability data
    return JSON.stringify({
      error: 'Calendar data not available',
      message: 'Please ensure calendar permissions are granted',
      date: requestedDate,
      intervals: []
    });
  } catch (error) {
    console.error('Error in getAvailability:', error);
    return JSON.stringify({
      error: 'Failed to retrieve calendar data',
      date: requestedDate,
      intervals: []
    });
  }
}

async function checkTimeSlot(
  args: any, 
  userId: string, 
  supabase: any,
  availabilityContext?: any
): Promise<string> {
  const { start_time, end_time, date } = args;
  const today = new Date().toISOString().split('T')[0];
  const checkDate = date || today;
  
  try {
    // Parse the requested time slot
    const [startHour, startMin] = start_time.split(':').map(Number);
    const [endHour, endMin] = end_time.split(':').map(Number);
    
    const startMinutes = startHour * 60 + startMin;
    const endMinutes = endHour * 60 + endMin;
    const durationMinutes = endMinutes - startMinutes;
    
    if (durationMinutes <= 0) {
      return JSON.stringify({
        date: checkDate,
        start_time,
        end_time,
        available: false,
        reason: 'Invalid time range'
      });
    }
    
    // If client provided availability context, check against it
    if (availabilityContext && availabilityContext.intervals) {
      const freeBlocks = availabilityContext.intervals;
      
      // Check if the requested slot fits within any free block
      const isAvailable = freeBlocks.some((block: any) => {
        const [blockStartH, blockStartM] = block.start.split(':').map(Number);
        const [blockEndH, blockEndM] = block.end.split(':').map(Number);
        
        const blockStartMinutes = blockStartH * 60 + blockStartM;
        const blockEndMinutes = blockEndH * 60 + blockEndM;
        
        return startMinutes >= blockStartMinutes && endMinutes <= blockEndMinutes;
      });
      
      return JSON.stringify({
        date: checkDate,
        start_time,
        end_time,
        duration_minutes: durationMinutes,
        available: isAvailable,
        checked_at: new Date().toISOString(),
        source: 'client_calendar',
        ...(!isAvailable && { reason: 'Time slot conflicts with calendar events or outside free blocks' })
      });
    }
    
    // Fallback: no availability data
    return JSON.stringify({
      date: checkDate,
      start_time,
      end_time,
      duration_minutes: durationMinutes,
      available: false,
      error: 'Calendar data not available',
      reason: 'Please ensure calendar permissions are granted'
    });
  } catch (error) {
    console.error('Error in checkTimeSlot:', error);
    return JSON.stringify({
      date: checkDate,
      start_time,
      end_time,
      available: false,
      error: 'Failed to check time slot'
    });
  }
}

// System prompts for each request kind
const SYSTEM_PROMPTS = {
  plan: `You are Tempo Coach, an AI assistant for the Tempo Pilot focus app. Your role is to help users plan their day with focused work blocks.

CALENDAR ACCESS: You have access to calendar tools that let you check the user's real-time availability:
- Use get_availability() to see all their free time slots for today
- Use check_time_slot() to verify if specific times are available
- Always check their calendar when they ask about scheduling or availability

Guidelines:
- Be concise, actionable, and encouraging
- Suggest realistic focus blocks (typically 25-90 minutes)
- Use your calendar tools to provide accurate, real-time availability
- Never ask users to paste raw calendar event titles or descriptions
- Keep all advice generic and privacy-conscious
- No medical, financial, or legal advice
- Stay focused on time management and productivity

Tone: Friendly, motivating, practical. Keep responses under 200 words unless the user asks for detail.

When a user asks about their schedule or free time, ALWAYS use get_availability() first to check their current calendar status.`,

  replan: `You are Tempo Coach, an AI assistant for the Tempo Pilot focus app. Your role is to help users adjust their plan when interruptions or changes occur.

CALENDAR ACCESS: You have calendar tools available:
- Use get_availability() to see their current free time slots
- Use check_time_slot() to verify if specific times are still available

Guidelines:
- Acknowledge the change without judgment
- Use your calendar tools to suggest realistic adjustments to remaining time
- Help users re-prioritize tasks based on actual availability
- Encourage them to protect at least one focus block if possible
- Never ask users to paste raw calendar event titles or descriptions
- Keep all advice generic and privacy-conscious
- No medical, financial, or legal advice
- Stay focused on time management and productivity

Tone: Supportive, flexible, solution-oriented. Keep responses under 200 words unless the user asks for detail.

When a user needs to replan, check their current availability first, then help them adapt their schedule.`,

  reflect: `You are Tempo Coach, an AI assistant for the Tempo Pilot focus app. Your role is to help users reflect on their focus sessions and learn from them.

CALENDAR ACCESS: You have calendar tools available:
- Use get_availability() to see upcoming free time for future planning
- Use check_time_slot() to help plan tomorrow's sessions

Guidelines:
- Ask open-ended questions to encourage reflection
- Celebrate progress and completed focus blocks
- Help identify patterns in what works and what doesn't
- Use calendar tools to suggest specific times for tomorrow's sessions
- Never ask users to paste raw calendar event titles or descriptions
- Keep all advice generic and privacy-conscious
- No medical, financial, or legal advice
- Stay focused on time management and productivity

Tone: Curious, affirming, growth-oriented. Keep responses under 200 words unless the user asks for detail.

When a user reflects on their day, help them extract insights and check their availability to plan better for tomorrow.`,
};

function formatAvailabilityContext(context: any): string {
  if (!context || !context.intervals || context.intervals.length === 0) {
    return "No calendar data available.";
  }
  
  const slots = context.intervals.map((slot: any) => `${slot.start} - ${slot.end} (${slot.minutes} min)`).join(', ');
  const tz = context.tz || 'local time';
  const day = context.day || 'today';
  
  return `Current calendar availability for ${day} (${tz}): ${slots}`;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Validate authentication
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ code: 'unauthorized', message: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Supabase client with service role for validation
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get user from JWT
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ code: 'unauthorized', message: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const userId = user.id;
    const requestId = crypto.randomUUID();
    console.log(`[${requestId}] Request from user: ${userId.substring(0, 8)}...`);

    // 2. Fetch profile metadata and feature flags
    const [profileResult, flagResult] = await Promise.all([
      supabase.from('profiles').select('metadata').eq('id', userId).single(),
      supabase.from('feature_flags').select('value').eq('key', 'ai_chat_enabled').single(),
    ]);

    // Check tester cohort
    const isTester = profileResult.data?.metadata?.tester === true;
    if (!isTester) {
      console.log(`[${requestId}] Denied: not in tester cohort`);
      return new Response(
        JSON.stringify({ code: 'not_tester', message: 'AI chat is only available to testers' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check feature flag
    const flagEnabled = flagResult.data?.value === true || flagResult.data?.value?.enabled === true;
    if (!flagEnabled) {
      console.log(`[${requestId}] Denied: feature flag disabled`);
      return new Response(
        JSON.stringify({ code: 'flag_off', message: 'AI chat is currently disabled' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Parse and validate request
    const payload: RequestPayload = await req.json();
    
    if (!payload.kind || !['plan', 'replan', 'reflect'].includes(payload.kind)) {
      return new Response(
        JSON.stringify({ code: 'invalid_request', message: 'Invalid kind parameter' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!Array.isArray(payload.messages) || payload.messages.length === 0) {
      return new Response(
        JSON.stringify({ code: 'invalid_request', message: 'Messages array required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate message size (prevent oversized payloads)
    const totalChars = payload.messages.reduce((sum, msg) => sum + (msg.content?.length || 0), 0);
    if (totalChars > 10000) {
      return new Response(
        JSON.stringify({ code: 'payload_too_large', message: 'Message content exceeds maximum size' }),
        { status: 413, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[${requestId}] Valid request: kind=${payload.kind}, messages=${payload.messages.length}`);
    console.log(`[${requestId}] Availability context:`, JSON.stringify(payload.availability_context || null));

    // 4. Call Azure OpenAI with streaming
    const azureEndpoint = Deno.env.get('AZURE_OPENAI_ENDPOINT');
    const azureKey = Deno.env.get('AZURE_OPENAI_KEY');
    const deploymentMini = Deno.env.get('AZURE_OPENAI_DEPLOYMENT_MINI');
    const deploymentFallback = Deno.env.get('AZURE_OPENAI_DEPLOYMENT_FALLBACK');
    const apiVersion = Deno.env.get('AZURE_OPENAI_API_VERSION') || '2024-07-18-preview';

    if (!azureEndpoint || !azureKey) {
      console.error(`[${requestId}] Missing Azure OpenAI credentials`);
      return new Response(
        JSON.stringify({ code: 'config_error', message: 'Azure OpenAI configuration incomplete' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!deploymentMini) {
      console.error(`[${requestId}] Missing primary Azure deployment name`);
      return new Response(
        JSON.stringify({ code: 'config_error', message: 'Primary Azure deployment not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    let normalizedEndpoint: string;
    let endpointPathWarning = false;

    try {
      const endpointUrl = new URL(azureEndpoint);
      const trimmedPath = endpointUrl.pathname.replace(/\/+$|^\/+/, '');

      if (trimmedPath && trimmedPath !== '') {
        endpointPathWarning = true;
      }

      normalizedEndpoint = `${endpointUrl.origin}`;
    } catch (_error) {
      normalizedEndpoint = azureEndpoint.replace(/\/$/, '');
    }

    let model = deploymentMini;
    let attempt = 0;
    let lastError: Error | null = null;
    let missingDeployment = false;
    let lastDeployment = model;

    const streamAzureResponse = (
      response: Response,
      modelName: string,
      userId: string,
      supabaseClient: any,
      requestId: string,
      availabilityContext?: any,
    ) => {
      const { readable, writable } = new TransformStream();
      const writer = writable.getWriter();
      const encoder = new TextEncoder();

      (async () => {
        try {
          await writer.write(encoder.encode(`event: start\ndata: ${JSON.stringify({ model: modelName })}\n\n`));

          let tokensIn = 0;
          let tokensOut = 0;
          const reader = response.body!.getReader();
          const decoder = new TextDecoder();
          let buffer = '';
          let pendingToolCalls: any[] = [];

          while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split('\n');
            buffer = lines.pop() || '';

            for (const line of lines) {
              if (line.startsWith('data: ')) {
                const data = line.slice(6);

                if (data === '[DONE]') {
                  // Execute any pending tool calls before ending
                  if (pendingToolCalls.length > 0) {
                    await writer.write(
                      encoder.encode(`event: tool_calls_start\ndata: ${JSON.stringify({ tool_calls: pendingToolCalls })}\n\n`)
                    );

                    // Execute each tool call with timeout
                    for (const toolCall of pendingToolCalls) {
                      try {
                        const args = JSON.parse(toolCall.function.arguments);
                        
                        // Add 10-second timeout to prevent hanging
                        const timeoutPromise = new Promise((_, reject) => 
                          setTimeout(() => reject(new Error('Tool execution timeout')), 10000)
                        );
                        
                        const result = await Promise.race([
                          executeCalendarTool(
                            toolCall.function.name,
                            args,
                            userId,
                            supabaseClient,
                            availabilityContext
                          ),
                          timeoutPromise
                        ]);
                        
                        await writer.write(
                          encoder.encode(`event: tool_result\ndata: ${JSON.stringify({ 
                            tool_call_id: toolCall.id, 
                            result: result 
                          })}\n\n`)
                        );
                      } catch (error) {
                        console.error(`[${requestId}] Tool execution failed for ${toolCall.function.name}:`, error);
                        await writer.write(
                          encoder.encode(`event: tool_result\ndata: ${JSON.stringify({ 
                            tool_call_id: toolCall.id, 
                            error: `Tool execution failed: ${error.message}` 
                          })}\n\n`)
                        );
                      }
                    }

                    await writer.write(
                      encoder.encode(`event: tool_calls_complete\ndata: {}\n\n`)
                    );
                  }

                  await writer.write(
                    encoder.encode(`event: end\ndata: ${JSON.stringify({ usage: { in: tokensIn, out: tokensOut } })}\n\n`)
                  );
                  continue;
                }

                try {
                  const parsed = JSON.parse(data);

                  if (parsed.usage) {
                    tokensIn = parsed.usage.prompt_tokens || 0;
                    tokensOut = parsed.usage.completion_tokens || 0;
                  }

                  const choice = parsed.choices?.[0];
                  const delta = choice?.delta;

                  // Handle content chunks
                  if (delta?.content) {
                    await writer.write(
                      encoder.encode(`event: chunk\ndata: ${JSON.stringify({ delta: delta.content })}\n\n`)
                    );
                  }

                  // Handle tool calls
                  if (delta?.tool_calls) {
                    for (const toolCallDelta of delta.tool_calls) {
                      const index = toolCallDelta.index;
                      
                      // Initialize tool call if it doesn't exist
                      if (!pendingToolCalls[index]) {
                        pendingToolCalls[index] = {
                          id: toolCallDelta.id || `call_${Date.now()}_${index}`,
                          type: 'function',
                          function: {
                            name: '',
                            arguments: ''
                          }
                        };
                      }
                      
                      // Accumulate function name and arguments
                      if (toolCallDelta.function?.name) {
                        pendingToolCalls[index].function.name += toolCallDelta.function.name;
                      }
                      if (toolCallDelta.function?.arguments) {
                        pendingToolCalls[index].function.arguments += toolCallDelta.function.arguments;
                      }
                    }
                  }

                  // Check if we have complete tool calls and execute immediately
                  if (choice?.finish_reason === 'tool_calls' && pendingToolCalls.length > 0) {
                    await writer.write(
                      encoder.encode(`event: tool_calls_start\ndata: ${JSON.stringify({ tool_calls: pendingToolCalls })}\n\n`)
                    );

                    // Execute tools and collect results
                    const toolResults: any[] = [];
                    
                    for (const toolCall of pendingToolCalls) {
                      try {
                        const args = JSON.parse(toolCall.function.arguments);
                        
                        const timeoutPromise = new Promise((_, reject) => 
                          setTimeout(() => reject(new Error('Tool execution timeout')), 8000)
                        );
                        
                        const result = await Promise.race([
                          executeCalendarTool(
                            toolCall.function.name,
                            args,
                            userId,
                            supabaseClient,
                            availabilityContext
                          ),
                          timeoutPromise
                        ]);
                        
                        toolResults.push({
                          tool_call_id: toolCall.id,
                          role: 'tool',
                          content: JSON.stringify(result)
                        });
                        
                        await writer.write(
                          encoder.encode(`event: tool_result\ndata: ${JSON.stringify({ 
                            tool_call_id: toolCall.id, 
                            result: result 
                          })}\n\n`)
                        );
                      } catch (error) {
                        console.error(`[${requestId}] Immediate tool execution failed for ${toolCall.function.name}:`, error);
                        
                        toolResults.push({
                          tool_call_id: toolCall.id,
                          role: 'tool',
                          content: JSON.stringify({ error: error.message })
                        });
                        
                        await writer.write(
                          encoder.encode(`event: tool_result\ndata: ${JSON.stringify({ 
                            tool_call_id: toolCall.id, 
                            error: `Tool execution failed: ${error.message}` 
                          })}\n\n`)
                        );
                      }
                    }

                    await writer.write(
                      encoder.encode(`event: tool_calls_complete\ndata: {}\n\n`)
                    );
                    
                    // Send a simple completion message instead of complex nested streaming
                    const hasResults = toolResults.some(result => !JSON.parse(result.content).error);
                    
                    if (hasResults) {
                      await writer.write(
                        encoder.encode(`event: chunk\ndata: ${JSON.stringify({ delta: "\n\nBased on your calendar data, I can see your availability. Let me analyze this for you..." })}\n\n`)
                      );
                      
                      // Process the first successful result to provide immediate feedback
                      const successfulResult = toolResults.find(result => !JSON.parse(result.content).error);
                      if (successfulResult) {
                        try {
                          let data = JSON.parse(successfulResult.content);
                          
                          // Handle double-encoded JSON
                          if (typeof data === 'string') {
                            data = JSON.parse(data);
                          }
                          
                          // Check for intervals (client format) or free_blocks (server format)
                          const slots = data.intervals || data.free_blocks || data.free_slots || [];
                          
                          if (slots.length > 0) {
                            const slotsText = slots.map((slot: any) => 
                              `${slot.start} - ${slot.end} (${slot.minutes || 'N/A'} min)`
                            ).join(', ');
                            
                            const message = `\n\n🎯 Great! I can see your available time today: ${slotsText}\n\nThat's ${Math.floor((slots[0].minutes || 0) / 60)} hours and ${(slots[0].minutes || 0) % 60} minutes of focused work time! Would you like me to help you plan some focus blocks?`;
                            
                            await writer.write(
                              encoder.encode(`event: chunk\ndata: ${JSON.stringify({ delta: message })}\n\n`)
                            );
                          } else {
                            await writer.write(
                              encoder.encode(`event: chunk\ndata: ${JSON.stringify({ delta: "\n\n📅 Your calendar appears to be fully booked today with no available time slots. Consider reviewing your schedule or planning for tomorrow!" })}\n\n`)
                            );
                          }
                        } catch (e) {
                          await writer.write(
                            encoder.encode(`event: chunk\ndata: ${JSON.stringify({ delta: "\n\nI received your calendar data but had trouble processing it. Please try asking again." })}\n\n`)
                          );
                        }
                      }
                    } else {
                      await writer.write(
                        encoder.encode(`event: chunk\ndata: ${JSON.stringify({ delta: "\n\nI encountered an issue accessing your calendar data. Please make sure calendar permissions are granted and try again." })}\n\n`)
                      );
                    }
                    
                    // Clear pending tool calls as they've been executed
                    pendingToolCalls = [];
                    
                    // End the stream after tool execution
                    await writer.write(
                      encoder.encode(`event: end\ndata: ${JSON.stringify({ usage: { in: tokensIn, out: tokensOut } })}\n\n`)
                    );
                    break; // Exit the streaming loop
                  }
                } catch (e) {
                  console.error(`[${requestId}] Failed to parse SSE chunk:`, e);
                }
              }
            }
          }

          // Always log the message for quota tracking, even if token counts are unavailable
          const { error: insertError } = await supabase.from('ai_messages').insert({
            user_id: userId,
            kind: payload.kind,
            tokens_in: tokensIn,
            tokens_out: tokensOut,
            created_at: new Date().toISOString(),
          });

          if (insertError) {
            console.error(`[${requestId}] Failed to log usage:`, insertError);
          } else {
            console.log(`[${requestId}] Usage logged: in=${tokensIn}, out=${tokensOut}`);
          }

          await writer.close();
        } catch (error) {
          console.error(`[${requestId}] Stream error:`, error);
          await writer.write(
            encoder.encode(`event: error\ndata: ${JSON.stringify({ code: 'stream_error', message: 'Stream interrupted' })}\n\n`)
          );
          await writer.close();
        }
      })();

      return new Response(readable, {
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          Connection: 'keep-alive',
        },
      });
    };

    // Retry logic with exponential backoff
    const makeAzureRequest = async (deployment: string, customMessages?: AzureMessage[]): Promise<Response> => {
      let azureMessages: AzureMessage[];
      
      if (customMessages) {
        // Use custom messages (for tool result processing)
        azureMessages = customMessages;
      } else {
        // Inject system prompt based on kind
        let systemPrompt = SYSTEM_PROMPTS[payload.kind];
        
        // Include availability context in system prompt if provided
        if (payload.availability_context) {
          const availabilityInfo = formatAvailabilityContext(payload.availability_context);
          systemPrompt += `\n\n${availabilityInfo}`;
        }
        
        azureMessages = [
          { role: 'system', content: systemPrompt },
          ...payload.messages.map(m => ({
            role: m.role,
            content: m.content,
          })),
        ];
      }

      const azureUrl = `${normalizedEndpoint}/openai/deployments/${deployment}/chat/completions?api-version=${apiVersion}`;
      
      // Add timeout to prevent hanging requests
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 second timeout
      
      try {
        const response = await fetch(azureUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'api-key': azureKey,
          },
          body: JSON.stringify({
            messages: azureMessages,
            ...(customMessages ? {} : { 
              tools: CALENDAR_TOOLS,
              tool_choice: "auto"
            }),
            stream: true,
            max_tokens: 1000,
            temperature: 0.7,
          }),
          signal: controller.signal,
        });
        clearTimeout(timeoutId);
        return response;
      } catch (error) {
        clearTimeout(timeoutId);
        throw error;
      }
    };

    // Try primary model with retries
    while (attempt < 3) {
      try {
        const response = await makeAzureRequest(model);
        
        if (response.ok) {
          console.log(`[${requestId}] Azure streaming started: model=${model}`);
          return streamAzureResponse(
            response, 
            model, 
            userId, 
            supabase, 
            requestId, 
            payload.availability_context
          );
        } else {
          const errorText = await response.text();
          lastError = new Error(`Azure returned ${response.status}: ${errorText}`);
          lastDeployment = model;

          if (response.status === 404) {
            missingDeployment = true;
          }

          console.log(`[${requestId}] Attempt ${attempt + 1} failed: ${response.status}`);
          console.log(`[${requestId}] Azure error body:`, errorText);
          console.log(`[${requestId}] Azure URL:`, `${normalizedEndpoint}/openai/deployments/${model}/chat/completions?api-version=${apiVersion}`);
        }
      } catch (error) {
        lastError = error as Error;
        console.log(`[${requestId}] Attempt ${attempt + 1} error:`, error);
      }

      attempt++;
      if (attempt < 3) {
        const delay = Math.pow(2, attempt - 1) * 1000; // 1s, 2s
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }

    // Try fallback model if primary failed
    if (model === deploymentMini) {
      if (deploymentFallback) {
        console.log(`[${requestId}] Switching to fallback model: ${deploymentFallback}`);
        model = deploymentFallback;

        try {
          const response = await makeAzureRequest(model);
          if (response.ok) {
            console.log(`[${requestId}] Fallback model streaming started`);
            return streamAzureResponse(
              response, 
              model, 
              userId, 
              supabase, 
              requestId, 
              payload.availability_context
            );
          }

          const errorText = await response.text();
          lastError = new Error(`Fallback Azure returned ${response.status}: ${errorText}`);
          lastDeployment = model;
          if (response.status === 404) {
            missingDeployment = true;
          }
          console.log(`[${requestId}] Fallback attempt failed: ${response.status}`);
          console.log(`[${requestId}] Fallback Azure error body:`, errorText);
        } catch (error) {
          lastError = error as Error;
          console.error(`[${requestId}] Fallback model also failed:`, error);
        }
      } else {
        console.log(`[${requestId}] No fallback deployment configured`);
      }
    }

    // All attempts failed
    if (missingDeployment) {
      const hint = endpointPathWarning
        ? 'Endpoint should not include /openai/... path segments. Use the base resource URL only.'
        : 'Verify AZURE_OPENAI_ENDPOINT, deployment name, and api-version in Supabase function config.';

      return new Response(
        JSON.stringify({
          code: 'azure_config',
          message: `Azure deployment '${lastDeployment}' not found`,
          details: hint,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ 
        code: 'azure_error', 
        message: 'Failed to get response from AI service',
        details: lastError?.message 
      }),
      { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Unexpected error:', error);
    return new Response(
      JSON.stringify({ 
        code: 'internal_error', 
        message: 'An unexpected error occurred',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
